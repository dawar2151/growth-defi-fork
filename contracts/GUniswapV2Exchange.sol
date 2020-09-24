// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GExchange } from "./GExchange.sol";

import { Router02 } from "./interop/UniswapV2.sol";

import { UniswapV2ExchangeAbstraction } from "./modules/UniswapV2ExchangeAbstraction.sol";

import { $ } from "./network/$.sol";

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

	// used by stress-test
	function faucet(address _token, uint256 _amount) public payable {
		address payable _from = msg.sender;
		uint256 _value = msg.value;
		address _router = $.UniswapV2_ROUTER02;
		address[] memory _path = new address[](2);
		_path[0] = Router02(_router).WETH();
		_path[1] = _token;
		uint256 _spent = Router02(_router).swapETHForExactTokens{value: _value}(_amount, _path, _from, block.timestamp)[0];
		_from.transfer(_value - _spent);
	}
	receive() external payable {}
}
