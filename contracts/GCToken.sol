// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GToken } from "./GToken.sol";

interface GCToken is GToken
{
	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) external pure returns (uint256 _cost);
	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost);

	function underlyingToken() external view returns (address _underlyingToken);
	function exchangeRate() external view returns (uint256 _exchangeRate);
	function totalReserveUnderlying() external view returns (uint256 _totalReserveUnderlying);
	function lendingReserveUnderlying() external view returns (uint256 _lendingReserveUnderlying);
	function borrowingReserveUnderlying() external view returns (uint256 _borrowingReserveUnderlying);
	function miningExchange() external view returns (address _miningExchange);
	function miningGulpRange() external view returns (uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount);
	function leverageEnabled() external view returns (bool _leverageEnabled);

	function depositUnderlying(uint256 _underlyingCost) external;
	function withdrawUnderlying(uint256 _grossShares) external;

	function setMiningExchange(address _miningExchange) external;
	function setMiningGulpRange(uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) external;
	function setLeverageEnabled(bool _leverageEnabled) external;
}
