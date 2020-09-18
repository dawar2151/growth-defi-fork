// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { GToken } from "./GToken.sol";
import { GFormulae } from "./GFormulae.sol";
import { GLiquidityPoolManager } from "./GLiquidityPoolManager.sol";
import { G } from "./G.sol";

contract GTokenBase is ERC20, Ownable, ReentrancyGuard, GToken
{
	using GLiquidityPoolManager for GLiquidityPoolManager.Self;

	uint256 constant DEPOSIT_FEE = 1e16; // 1%
	uint256 constant WITHDRAWAL_FEE = 1e16; // 1%

	address public immutable override stakesToken;
	address public immutable override reserveToken;

	GLiquidityPoolManager.Self lpm;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakesToken, address _reserveToken)
		ERC20(_name, _symbol) public
	{
		_setupDecimals(_decimals);
		stakesToken = _stakesToken;
		reserveToken = _reserveToken;
		lpm.init(_stakesToken, address(this));
	}

	function calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) public pure override returns (uint256 _netShares, uint256 _feeShares)
	{
		return GFormulae._calcDepositSharesFromCost(_cost, _totalReserve, _totalSupply, _depositFee);
	}

	function calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		return GFormulae._calcDepositCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee);
	}

	function calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) public pure override returns (uint256 _grossShares, uint256 _feeShares)
	{
		return GFormulae._calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
	}

	function calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		return GFormulae._calcWithdrawalCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee);
	}

	function totalReserve() public view virtual override returns (uint256 _totalReserve)
	{
		return G.getBalance(reserveToken);
	}

	function depositFee() public view override returns (uint256 _depositFee) {
		return lpm.hasPool() ? DEPOSIT_FEE : 0;
	}

	function withdrawalFee() public view override returns (uint256 _withdrawalFee) {
		return lpm.hasPool() ? WITHDRAWAL_FEE : 0;
	}

	function liquidityPool() public view override returns (address _liquidityPool)
	{
		return lpm.liquidityPool;
	}

	function liquidityPoolBurningRate() public view override returns (uint256 _burningRate)
	{
		return lpm.burningRate;
	}

	function liquidityPoolLastBurningTime() public view override returns (uint256 _lastBurningTime)
	{
		return lpm.lastBurningTime;
	}

	function liquidityPoolMigrationRecipient() public view override returns (address _migrationRecipient)
	{
		return lpm.migrationRecipient;
	}

	function liquidityPoolMigrationUnlockTime() public view override returns (uint256 _migrationUnlockTime)
	{
		return lpm.migrationUnlockTime;
	}

	function deposit(uint256 _cost) public override nonReentrant
	{
		address _from = msg.sender;
		require(_cost > 0, "cost must be greater than 0");
		(uint256 _netShares, uint256 _feeShares) = GFormulae._calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "shares must be greater than 0");
		require(_prepareDeposit(_cost), "operation not available at the moment");
		G.pullFunds(reserveToken, _from, _cost);
		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
		_adjustReserve();
	}

	function withdraw(uint256 _grossShares) public override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		require(_cost > 0, "cost must be greater than 0");
		require(_prepareWithdrawal(_cost), "operation not available at the moment");
		G.pushFunds(reserveToken, _from, _cost);
		_burn(_from, _grossShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
		_adjustReserve();
	}

	function allocateLiquidityPool(uint256 _stakesAmount, uint256 _sharesAmount) public override onlyOwner nonReentrant
	{
		address _from = msg.sender;
		G.pullFunds(stakesToken, _from, _stakesAmount);
		_transfer(_from, address(this), _sharesAmount);
		lpm.allocatePool(_stakesAmount, _sharesAmount);
	}

	function setLiquidityPoolBurningRate(uint256 _burningRate) public override onlyOwner nonReentrant
	{
		lpm.setBurningRate(_burningRate);
	}

	function burnLiquidityPoolPortion() public override onlyOwner nonReentrant
	{
		(uint256 _stakesAmount, uint256 _sharesAmount) = lpm.burnPoolPortion();
		_burnStakes(_stakesAmount);
		_burn(address(this), _sharesAmount);
		emit BurnLiquidityPoolPortion(_stakesAmount, _sharesAmount);
	}

	function initiateLiquidityPoolMigration(address _migrationRecipient) public override onlyOwner nonReentrant
	{
		lpm.initiatePoolMigration(_migrationRecipient);
		emit InitiateLiquidityPoolMigration(_migrationRecipient);
	}

	function cancelLiquidityPoolMigration() public override onlyOwner nonReentrant
	{
		address _migrationRecipient = lpm.cancelPoolMigration();
		emit CancelLiquidityPoolMigration(_migrationRecipient);
	}

	function completeLiquidityPoolMigration() public override onlyOwner nonReentrant
	{
		(address _migrationRecipient, uint256 _stakesAmount, uint256 _sharesAmount) = lpm.completePoolMigration();
		G.pushFunds(stakesToken, _migrationRecipient, _stakesAmount);
		_transfer(address(this), _migrationRecipient, _sharesAmount);
		emit CompleteLiquidityPoolMigration(_migrationRecipient, _stakesAmount, _sharesAmount);
	}

	function adjustReserve() public override onlyOwner nonReentrant
	{
		require(_adjustReserve(), "failure adjusting reserve");
	}

	function _prepareDeposit(uint256 _cost) internal virtual returns (bool _success)
	{
		return true;
	}

	function _prepareWithdrawal(uint256 _cost) internal virtual returns (bool _success)
	{
		return true;
	}

	function _adjustReserve() internal virtual returns (bool _success)
	{
		return true;
	}

	function _burnStakes(uint256 _stakesAmount) internal virtual
	{
		G.pushFunds(stakesToken, address(0), _stakesAmount);
	}

	event BurnLiquidityPoolPortion(uint256 _stakesAmount, uint256 _sharesAmount);
	event InitiateLiquidityPoolMigration(address indexed _migrationRecipient);
	event CancelLiquidityPoolMigration(address indexed _migrationRecipient);
	event CompleteLiquidityPoolMigration(address indexed _migrationRecipient, uint256 _stakesAmount, uint256 _sharesAmount);
}
