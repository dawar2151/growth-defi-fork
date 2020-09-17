// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GToken } from "./GToken.sol";

interface GCToken is GToken
{
	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) external pure returns (uint256 _cost);
	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) external pure returns (uint256 _underlyingCost);

	// function miningToken() external view returns (address _miningToken);
	// function leverageToken() external view returns (address _leverageToken);
	// function borrowToken() external view returns (address _borrowToken);
	// function leverageEnabled() external view returns (bool _leverageEnabled);
	// function leverageAdjustmentAmount() external view returns (uint256 _leverageAdjustmentAmount);
	// function idealCollateralizationRatio() external view returns (uint256 _idealCollateralizationRatio);
	// function limitCollateralizationRatio() external view returns (uint256 _limitCollateralizationRatio);
	function underlyingToken() external view returns (address _underlyingToken);
	function exchangeRate() external view returns (uint256 _exchangeRate);
	function totalReserveUnderlying() external view returns (uint256 _totalReserveUnderlying);

	function depositUnderlying(uint256 _underlyingCost) external;
	function withdrawUnderlying(uint256 _grossShares) external;
	function setLeverageEnabled(bool _leverageEnabled) external;
	function setLeverageAdjustmentAmount(uint256 _leverageAdjustmentAmount) external;
	function setIdealCollateralizationRatio(uint256 _idealCollateralizationRatio) external;
	function setLimitCollateralizationRatio(uint256 _limitCollateralizationRatio) external;
}
