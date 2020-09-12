// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface GToken is IERC20
{
	function calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) external pure returns (uint256 _netShares, uint256 _feeShares);
	function calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) external pure returns (uint256 _cost, uint256 _feeShares);
	function calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) external pure returns (uint256 _grossShares, uint256 _feeShares);
	function calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) external pure returns (uint256 _cost, uint256 _feeShares);

	function totalReserve() external returns (uint256 _totalReserve);
	function deposit(uint256 _cost) external;
	function withdraw(uint256 _grossShares) external;
	function setLiquidityPoolBurningRate(uint256 _burningRate) external;
	function allocateLiquidityPool(uint256 _stakeAmount, uint256 _sharesAmount) external;
	function burnLiquidityPoolPortion() external;
	function initiateLiquidityPoolMigration(address _migrationRecipient) external;
	function cancelLiquidityPoolMigration() external;
	function completeLiquidityPoolMigration() external;
}

interface GCToken is GToken
{
	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) external pure returns (uint256 _cost);
	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost);

	function totalReserveUnderlying() external returns (uint256 _totalReserveUnderlying);
	function depositUnderlying(uint256 _underlyingCost) external;
	function withdrawUnderlying(uint256 _grossShares) external;
}
