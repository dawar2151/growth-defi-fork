// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { CurveExchangeAbstraction } from "./CurveExchangeAbstraction.sol";
import { UniswapV2ExchangeAbstraction } from "./UniswapV2ExchangeAbstraction.sol";

library Conversions
{
	function _calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		if (_from == Addresses.DAI && _to == Addresses.USDC) return CurveExchangeAbstraction._calcConversionDAIToUSDCGivenDAI(_inputAmount);
		if (_from == Addresses.USDC && _to == Addresses.DAI) return CurveExchangeAbstraction._calcConversionUSDCToDAIGivenUSDC(_inputAmount);
		return UniswapV2ExchangeAbstraction._calcConversionOutputFromInput(_from, _to, _inputAmount);
	}

	function _calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		if (_from == Addresses.DAI && _to == Addresses.USDC) return CurveExchangeAbstraction._calcConversionDAIToUSDCGivenUSDC(_outputAmount);
		if (_from == Addresses.USDC && _to == Addresses.DAI) return CurveExchangeAbstraction._calcConversionUSDCToDAIGivenDAI(_outputAmount);
		return UniswapV2ExchangeAbstraction._calcConversionInputFromOutput(_from, _to, _outputAmount);
	}

	function _convertBalance(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		if (_from == Addresses.DAI && _to == Addresses.USDC) return CurveExchangeAbstraction._convertFundsDAIToUSDC(_inputAmount, _minOutputAmount);
		if (_from == Addresses.USDC && _to == Addresses.DAI) return CurveExchangeAbstraction._convertFundsUSDCToDAI(_inputAmount, _minOutputAmount);
		return UniswapV2ExchangeAbstraction._convertBalance(_from, _to, _inputAmount, _minOutputAmount);
	}
}
