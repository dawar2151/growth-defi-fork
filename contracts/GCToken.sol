// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GToken } from "./GToken.sol";

/**
 * @dev Complete top-level interface for gcTokens, implemented by the
 *      GCTokenBase contract. See GCTokenBase.sol for further documentation.
 */
interface GCToken is GToken
{
	// pure functions
	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) external pure returns (uint256 _cost);
	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost);
	function calcDepositSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) external pure returns (uint256 _netShares, uint256 _feeShares);
	function calcDepositUnderlyingCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost, uint256 _feeShares);
	function calcWithdrawalSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) external pure returns (uint256 _grossShares, uint256 _feeShares);
	function calcWithdrawalUnderlyingCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost, uint256 _feeShares);

	// view functions
	function miningToken() external view returns (address _miningToken);
	function growthToken() external view returns (address _growthToken);
	function underlyingToken() external view returns (address _underlyingToken);
	function exchangeRate() external view returns (uint256 _exchangeRate);
	function totalReserveUnderlying() external view returns (uint256 _totalReserveUnderlying);
	function lendingReserveUnderlying() external view returns (uint256 _lendingReserveUnderlying);
	function borrowingReserveUnderlying() external view returns (uint256 _borrowingReserveUnderlying);
	function exchange() external view returns (address _exchange);
	function miningGulpRange() external view returns (uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount);
	function growthGulpRange() external view returns (uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount);
	function collateralizationRatio() external view returns (uint256 _collateralizationRatio, uint256 _collateralizationMargin);

	// open functions
	function depositUnderlying(uint256 _underlyingCost) external;
	function withdrawUnderlying(uint256 _grossShares) external;

	// priviledged functions
	function setExchange(address _exchange) external;
	function setMiningGulpRange(uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) external;
	function setGrowthGulpRange(uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount) external;
	function setCollateralizationRatio(uint256 _collateralizationRatio, uint256 _collateralizationMargin) external;
}
