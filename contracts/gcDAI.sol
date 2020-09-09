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
	function depositUnderlying(uint256 _amount) external;
	function withdrawUnderlying(uint256 _shares) external;
	function burnSwapFees() external;
	function initiateLiquidityMigration(address _recipient) external;
	function completeLiquidityMigration() external;
}

contract gcDAI is gToken, ERC20, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	uint256 constant MINT_FEE = 10000000000000000; // 1%
	uint256 constant BURN_FEE = 10000000000000000; // 1%

	IERC20 public immutable token = IERC20(Addresses.DAI);
	CToken public immutable ctoken = CToken(Addresses.cDAI);

	Pool public pool;

	uint256 lastFeeBurning = 0;

	uint256 migrationLock = uint256(-1);
	address migrationRecipient = address(0);

	constructor () ERC20("growth cDAI", "gcDAI") public
	{
		_setupDecimals(18);
	}

	function allocateLiquidityPool(uint256 _stakeAmount, uint256 _sharesAmount) public onlyOwner nonReentrant
	{
		address _from = msg.sender;
		require(address(pool) == address(0), "pool already allocated");
		pool = _createLiquidityPool(_from, _stakeAmount, _sharesAmount);
	}

	function totalReserve() public view returns (uint256 _reserve)
	{
		return ctoken.balanceOf(address(this));
	}

	function calcMintingShares(uint256 _cost, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _netShares, uint256 _feeShares)
	{
		uint256 _grossShares = _reserve == 0 ? _cost : _cost.mul(_supply).div(_reserve);
		_netShares = _grossShares.mul(1000000000000000000).div(_fee.add(1000000000000000000));
		_feeShares = _grossShares.sub(_netShares);
		return (_netShares, _feeShares);
	}

	function calcMintingCost(uint256 _netShares, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _grossShares = _netShares.mul(_fee.add(1000000000000000000)).div(1000000000000000000);
		_cost = _supply == 0 ? _grossShares : _grossShares.mul(_reserve).div(_supply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}

	function calcBurningShares(uint256 _cost, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _grossShares, uint256 _feeShares)
	{
		uint256 _netShares = _reserve == 0 ? _cost : _cost.mul(_supply).div(_reserve);
		_grossShares = _netShares.mul(1000000000000000000).div(_fee.sub(1000000000000000000));
		_feeShares = _grossShares.sub(_netShares);
		return (_grossShares, _feeShares);
	}

	function calcBurningCost(uint256 _grossShares, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _netShares = _grossShares.mul(_fee.sub(1000000000000000000)).div(1000000000000000000);
		_cost = _supply == 0 ? _netShares : _netShares.mul(_reserve).div(_supply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}

	function deposit(uint256 _cost) external override nonReentrant
	{
		address _from = msg.sender;
		require(_cost > 0, "deposit must be greater than 0");

		(uint256 _netShares, uint256 _feeShares) = calcMintingShares(_cost, totalReserve(), totalSupply(), MINT_FEE);

		IERC20(ctoken).safeTransferFrom(_from, address(this), _cost);

		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));

		if (address(pool) != address(0)) _joinLiquidityPool(pool, 0, balanceOf(address(this)));

		// TODO USDC borrow

		_convertLiquidityMiningProfits();
	}

	function depositUnderlying(uint256 _amount) external override nonReentrant
	{
		address _from = msg.sender;
		require(_amount > 0, "deposit must be greater than 0");

		uint256 _reserve = totalReserve();

		token.safeTransferFrom(_from, address(this), _amount);
		token.safeApprove(address(ctoken), _amount);

		uint256 _result = ctoken.mint(_amount);
		require(_result == 0, "mint failure");

		uint256 _newReserve = totalReserve();
		uint256 _cost = _newReserve.sub(_reserve);

		(uint256 _netShares, uint256 _feeShares) = calcMintingShares(_cost, _reserve, totalSupply(), MINT_FEE);

		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));

		if (address(pool) != address(0)) _joinLiquidityPool(pool, 0, balanceOf(address(this)));

		// TODO USDC borrow

		_convertLiquidityMiningProfits();
	}

	function withdraw(uint256 _shares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_shares > 0, "withdraw must be greater than 0");
		require(_shares <= balanceOf(_from), "insufficient balance");

		(uint256 _cost, uint256 _feeShares) = calcBurningCost(_shares, totalReserve(), totalSupply(), BURN_FEE);

		_burn(_from, _shares);
		_mint(address(this), _feeShares.div(2));

		IERC20(ctoken).safeTransfer(_from, _cost);

		if (address(pool) != address(0)) _joinLiquidityPool(pool, 0, balanceOf(address(this)));

		// TODO USDC repay

		_convertLiquidityMiningProfits();
	}

	function withdrawUnderlying(uint256 _shares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_shares > 0, "withdraw must be greater than 0");
		require(_shares <= balanceOf(_from), "insufficient balance");

		(uint256 _cost, uint256 _feeShares) = calcBurningCost(_shares, totalReserve(), totalSupply(), BURN_FEE);

		_burn(_from, _shares);
		_mint(address(this), _feeShares.div(2));

		uint256 _result = ctoken.redeem(_cost);
		require(_result == 0, "redeem failure");

		uint256 _amount = token.balanceOf(address(this));
		token.safeTransfer(_from, _amount);

		if (address(pool) != address(0)) _joinLiquidityPool(pool, 0, balanceOf(address(this)));

		// TODO USDC repay

		_convertLiquidityMiningProfits();
	}

	function burnSwapFees() external override onlyOwner nonReentrant
	{
		require(address(pool) != address(0));
		require(lastFeeBurning + 7 days < now);

		// TODO estimate based on swaps
		uint256 _feeStake = 0;
		uint256 _feeShares = 0;

		_exitLiquidityPool(pool, _feeStake, _feeShares);

		IERC20(Addresses.GRO).safeTransfer(address(0), _feeStake);
		_burn(address(this), _feeShares);

		lastFeeBurning = now;
	}

	function initiateLiquidityMigration(address _recipient) external override onlyOwner
	{
		require(address(pool) != address(0));
		require(migrationRecipient != address(0));
		migrationLock = now + 7 days;
		migrationRecipient = _recipient;
	}

	function completeLiquidityMigration() external override onlyOwner nonReentrant
	{
		require(now > migrationLock);
		_migrateLiquidityPool(pool, migrationRecipient);
		migrationLock = uint256(-1);
		migrationRecipient = address(0);
	}

	/* Reserves management */

	function _convertLiquidityMiningProfits() internal
	{
		IERC20 COMP = IERC20(Addresses.COMP);
		_convertBalance(COMP, ctoken, COMP.balanceOf(address(this)));
	}

	function _convertBalance(IERC20 _from, IERC20 _to, uint256 _amount) internal
	{
		if (_amount == 0) return;
		// TODO verify 1inch parts parameter
		Oneinch oneinch = Oneinch(Addresses.Oneinch);
		(uint256 _returnAmount, uint256[] memory _distribution) = oneinch.getExpectedReturn(_from, _to, _amount, 100, 0);
		_from.safeApprove(address(oneinch), _amount);
		oneinch.swap(_from, _to, _amount, _returnAmount, _distribution, 0);
	}

	/* LP abstractions */

	uint256 constant POOL_GRO_WEIGHT = 500000000000000000; // 50%
	uint256 constant POOL_GTOKEN_WEIGHT = 500000000000000000; // 50%
	uint256 constant POOL_SWAP_FEE = 100000000000000000; // 10%

	function _createLiquidityPool(address _from, uint256 _stakeAmount, uint256 _sharesAmount) internal returns (Pool _pool)
	{
		IERC20(Addresses.GRO).safeTransferFrom(_from, address(this), _stakeAmount);
		IERC20(Addresses.GRO).safeApprove(address(_pool), _stakeAmount);

		IERC20(this).safeTransferFrom(_from, address(this), _sharesAmount);
		IERC20(this).safeApprove(address(_pool), _sharesAmount);

		_pool = Factory(Addresses.Balancer_Factory).newBPool();
		_pool.bind(address(Addresses.GRO), _stakeAmount, POOL_GRO_WEIGHT);
		_pool.bind(address(this), _sharesAmount, POOL_GTOKEN_WEIGHT);
		_pool.setSwapFee(POOL_SWAP_FEE);
		_pool.finalize();
		return _pool;
	}

	function _joinLiquidityPool(Pool _pool, uint256 _stakeAmount, uint256 _sharesAmount) internal
	{
		if (_stakeAmount > 0) {
			IERC20(Addresses.GRO).safeApprove(address(_pool), _stakeAmount);
			_pool.joinswapExternAmountIn(address(Addresses.GRO), _stakeAmount, 0);
		}
		if (_sharesAmount > 0) {
			IERC20(this).safeApprove(address(_pool), _sharesAmount);
			_pool.joinswapExternAmountIn(address(this), _sharesAmount, 0);
		}
	}

	function _exitLiquidityPool(Pool _pool, uint256 _stakeAmount, uint256 _sharesAmount) internal
	{
		if (_stakeAmount > 0) {
			_pool.exitswapExternAmountOut(address(Addresses.GRO), _stakeAmount, uint256(-1));
		}
		if (_sharesAmount > 0) {
			_pool.exitswapExternAmountOut(address(this), _sharesAmount, uint256(-1));
		}
	}

	function _migrateLiquidityPool(Pool _pool, address _recipient) internal
	{
		IERC20(_pool).safeTransfer(_recipient, _pool.balanceOf(address(this)));
	}
}
