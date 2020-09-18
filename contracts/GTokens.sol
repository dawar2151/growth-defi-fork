// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { GCTokenBase } from "./GCTokenBase.sol";
import { G } from "./G.sol";

contract gcDAI is GCTokenBase
{
	uint256 constant DEFAULT_LEVERAGE_ADJUSTMENT_AMOUNT = 1000e18; // 1000 DAI

	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 18, Addresses.GRO, Addresses.COMP, Addresses.cDAI, Addresses.cUSDC, DEFAULT_LEVERAGE_ADJUSTMENT_AMOUNT) public
	{
	}

	function _calcConversionUnderlyingToBorrowGivenUnderlying(uint256 _inputAmount) internal view override returns (uint256 _outputAmount)
	{
		return G.calcConversionDAIToUSDCGivenDAI(_inputAmount);
	}

	function _calcConversionUnderlyingToBorrowGivenBorrow(uint256 _outputAmount) internal view override returns (uint256 _inputAmount)
	{
		return G.calcConversionDAIToUSDCGivenUSDC(_outputAmount);
	}

	function _calcConversionBorrowToUnderlyingGivenUnderlying(uint256 _outputAmount) internal view override returns (uint256 _inputAmount)
	{
		return G.calcConversionUSDCToDAIGivenDAI(_outputAmount);
	}

	function _convertUnderlyingToBorrow(uint256 _inputAmount) internal override
	{
		return G.convertFundsDAIToUSDC(_inputAmount);
	}

	function _convertBorrowToUnderlying(uint256 _inputAmount) internal override
	{
		return G.convertFundsUSDCToDAI(_inputAmount);
	}
}
