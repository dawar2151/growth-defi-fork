// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GToken } from "./GToken.sol";

interface GCToken is GToken
{
	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) external pure returns (uint256 _cost);
	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost);

	function underlyingToken() external returns (address _underlyingToken);

	function exchangeRate() external returns (uint256 _exchangeRate);
	function totalReserveUnderlying() external returns (uint256 _totalReserveUnderlying);
	function depositUnderlying(uint256 _underlyingCost) external;
	function withdrawUnderlying(uint256 _grossShares) external;
}
