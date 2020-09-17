// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { Conversions } from "./Conversions.sol";
import { GCTokenBase } from "./GCTokenBase.sol";

contract gcDAI is Addresses, Conversions, GCTokenBase
{
	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 18, GRO, cDAI, COMP, cUSDC) public
	{
	}

	function _calcConversionUnderlyingToBorrowGivenUnderlying(uint256 _inputAmount) internal view override returns (uint256 _outputAmount)
	{
		return _calcConversionDAIToUSDCGivenDAI(_inputAmount);
	}

	function _calcConversionUnderlyingToBorrowGivenBorrow(uint256 _outputAmount) internal view override returns (uint256 _inputAmount)
	{
		return _calcConversionDAIToUSDCGivenUSDC(_outputAmount);
	}

	function _calcConversionBorrowToUnderlyingGivenUnderlying(uint256 _outputAmount) internal view override returns (uint256 _inputAmount)
	{
		return _calcConversionUSDCToDAIGivenDAI(_outputAmount);
	}

	function _convertUnderlyingToBorrow(uint256 _inputAmount) internal override
	{
		return _convertFundsDAIToUSDC(_inputAmount);
	}

	function _convertBorrowToUnderlying(uint256 _inputAmount) internal override
	{
		return _convertFundsUSDCToDAI(_inputAmount);
	}
}
