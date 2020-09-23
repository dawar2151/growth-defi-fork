// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GExchange } from "./GExchange.sol";

import { UniswapV2ExchangeAbstraction } from "./modules/UniswapV2ExchangeAbstraction.sol";

contract GUniswapV2Exchange is GExchange
{
	function calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) public view override returns (uint256 _outputAmount)
	{
		return UniswapV2ExchangeAbstraction._calcConversionOutputFromInput(_from, _to, _inputAmount);
	}

	function calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) public view override returns (uint256 _inputAmount)
	{
		return UniswapV2ExchangeAbstraction._calcConversionInputFromOutput(_from, _to, _outputAmount);
	}

	function convertFunds(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) public override returns (uint256 _outputAmount)
	{
		return UniswapV2ExchangeAbstraction._convertFunds(_from, _to, _inputAmount, _minOutputAmount);
	}
}
