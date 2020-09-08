// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { Addresses } from "./Addresses.sol";
import { Factory, Pool } from "./interop/Balancer.sol";
import { CToken } from "./interop/Compound.sol";
import { Oneinch } from "./interop/Oneinch.sol";

interface gToken is IERC20
{
	function calcMintingShares(uint256 _cost, uint256 _reserve, uint256 _supply, uint256 _fee) external pure returns (uint256 _netShares, uint256 _feeShares);
	function calcMintingCost(uint256 _netShares, uint256 _reserve, uint256 _supply, uint256 _fee) external pure returns (uint256 _cost, uint256 _feeShares);
	function calcBurningShares(uint256 _cost, uint256 _reserve, uint256 _supply, uint256 _fee) external pure returns (uint256 _grossShares, uint256 _feeShares);
	function calcBurningCost(uint256 _grossShares, uint256 _reserve, uint256 _supply, uint256 _fee) external pure returns (uint256 _cost, uint256 _feeShares);
	function deposit(uint256 _amount) external;
	function withdraw(uint256 _shares) external;
	function burnSwapFees() external;
	function initiateLiquidityMigration(address _recipient) external;
	function completeLiquidityMigration() external;
}

contract gcDAI is gToken, ERC20, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	IERC20 public immutable token = IERC20(Addresses.DAI);
	CToken public immutable ctoken = CToken(Addresses.cDAI);
	Pool public immutable pool;

	uint256 lastFeeBurning = 0;

	uint256 migrationLock = uint256(-1);
	address migrationRecipient = address(0);

	constructor () ERC20("growth cDAI", "gcDAI") public
	{
		address _from = msg.sender;

		_setupDecimals(18);

		uint256 bootstrapAmount = 1000000; // Balancer MIN_BALANCE
		IERC20(Addresses.GRO).safeTransferFrom(_from, address(this), bootstrapAmount);
		_mint(address(this), bootstrapAmount);

		Pool _pool = Factory(Addresses.Balancer_Factory).newBPool();
		_pool.bind(address(Addresses.GRO), bootstrapAmount, 500000000000000000); // 50%
		_pool.bind(address(this), bootstrapAmount, 500000000000000000); // 50%
		_pool.setSwapFee(10000000000000000); // 1%
		_pool.finalize();

		pool = _pool;
	}

	function calcMintingShares(uint256 _cost, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _netShares, uint256 _feeShares)
	{
		uint256 _grossShares = _cost.mul(_supply).div(_reserve);
		_netShares = _grossShares.mul(1000000000000000000).div(_fee.add(1000000000000000000));
		_feeShares = _grossShares.sub(_netShares);
		return (_netShares, _feeShares);
	}

	function calcMintingCost(uint256 _netShares, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _grossShares = _netShares.mul(_fee.add(1000000000000000000)).div(1000000000000000000);
		_cost = _grossShares.mul(_reserve).div(_supply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}

	function calcBurningShares(uint256 _cost, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _grossShares, uint256 _feeShares)
	{
		uint256 _netShares = _cost.mul(_supply).div(_reserve);
		_grossShares = _netShares.mul(1000000000000000000).div(_fee.sub(1000000000000000000));
		_feeShares = _grossShares.sub(_netShares);
		return (_grossShares, _feeShares);
	}

	function calcBurningCost(uint256 _grossShares, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _netShares = _grossShares.mul(_fee.sub(1000000000000000000)).div(1000000000000000000);
		_cost = _netShares.mul(_reserve).div(_supply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}

	function deposit(uint256 _amount) external override nonReentrant
	{
		address _from = msg.sender;
		require(_amount > 0, "deposit must be greater than 0");
		token.safeTransferFrom(_from, address(this), _amount);

		uint256 _reserve = ctoken.balanceOf(address(this));
		uint256 _supply = totalSupply();
		uint256 _fee = 10000000000000000; // 1%

		(uint256 _netShares, uint256 _feeShares) = calcMintingShares(_amount, _reserve, _supply, _fee);
		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2)); // TODO check if 0.5% fee increases or not supply

		token.approve(address(ctoken), _amount);
		ctoken.mint(_amount);

		// TODO USDC borrow

		pool.joinswapExternAmountIn(address(this), _feeShares.div(2), 0);

		uint256 _compBalance = IERC20(Addresses.COMP).balanceOf(address(this));
		if (IERC20(Addresses.COMP).balanceOf(address(this)) > 0) {
			Oneinch oneinch = Oneinch(Addresses.Oneinch);
			IERC20 COMP = IERC20(Addresses.COMP);
			(uint256 _returnAmount, uint256[] memory _distribution) = oneinch.getExpectedReturn(COMP, ctoken, _compBalance, 100, 0);
			oneinch.swap(COMP, ctoken, _compBalance, _returnAmount, _distribution, 0);
		}
	}

	function withdraw(uint256 _shares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_shares > 0, "withdraw must be greater than 0");
		require(_shares <= balanceOf(_from), "insufficient balance");

		uint256 _reserve = ctoken.balanceOf(address(this));
		uint256 _supply = totalSupply();
		uint256 _fee = 10000000000000000; // 1%

		(uint256 _cost, uint256 _feeShares) = calcBurningCost(_shares, _reserve, _supply, _fee);
		_burn(_from, _shares);
		_mint(address(this), _feeShares.div(2)); // TODO check if 0.5% fee increases or not supply

		ctoken.redeemUnderlying(_cost);
		token.safeTransfer(_from, _cost);

		// TODO USDC repay

		pool.joinswapExternAmountIn(address(this), _feeShares.div(2), 0);

		uint256 _compBalance = IERC20(Addresses.COMP).balanceOf(address(this));
		if (_compBalance > 0) {
			Oneinch oneinch = Oneinch(Addresses.Oneinch);
			IERC20 COMP = IERC20(Addresses.COMP);
			(uint256 _returnAmount, uint256[] memory _distribution) = oneinch.getExpectedReturn(COMP, ctoken, _compBalance, 100, 0);
			oneinch.swap(COMP, ctoken, _compBalance, _returnAmount, _distribution, 0);
		}
	}

	function burnSwapFees() external override onlyOwner nonReentrant
	{
		require(lastFeeBurning + 7 days < now);
		uint256 _feeShares = 0; // TODO estimate based on swaps
		pool.exitswapExternAmountOut(address(this), _feeShares, uint256(-1));
		_burn(address(this), _feeShares);
		lastFeeBurning = now;
	}

	function initiateLiquidityMigration(address _recipient) external override onlyOwner
	{
		require(migrationRecipient != address(0));
		migrationLock = now + 7 days;
		migrationRecipient = _recipient;
	}

	function completeLiquidityMigration() external override onlyOwner nonReentrant
	{
		require(now > migrationLock);
		uint256 _reserve = ctoken.balanceOf(address(this));
		ctoken.transfer(migrationRecipient, _reserve);
		migrationLock = uint256(-1);
		migrationRecipient = address(0);
	}
}
