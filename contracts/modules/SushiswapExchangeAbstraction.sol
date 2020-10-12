// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Transfers } from "./Transfers.sol";

import { Router02 } from "../interop/UniswapV2.sol";

import { $ } from "../network/$.sol";

library SushiswapExchangeAbstraction
{
	function _calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		address _router = $.Sushiswap_ROUTER02;
		address _WETH = Router02(_router).WETH();
		address[] memory _path = _buildPath(_from, _WETH, _to);
		return Router02(_router).getAmountsOut(_inputAmount, _path)[_path.length - 1];
	}

	function _calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		address _router = $.Sushiswap_ROUTER02;
		address _WETH = Router02(_router).WETH();
		address[] memory _path = _buildPath(_from, _WETH, _to);
		return Router02(_router).getAmountsIn(_outputAmount, _path)[0];
	}

	function _convertFunds(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		address _router = $.Sushiswap_ROUTER02;
		address _WETH = Router02(_router).WETH();
		address[] memory _path = _buildPath(_from, _WETH, _to);
		Transfers._approveFunds(_from, _router, _inputAmount);
		return Router02(_router).swapExactTokensForTokens(_inputAmount, _minOutputAmount, _path, address(this), uint256(-1))[_path.length - 1];
	}

	function _buildPath(address _from, address _WETH, address _to) internal pure returns (address[] memory _path)
	{
		if (_from == _WETH || _to == _WETH) {
			_path = new address[](2);
			_path[0] = _from;
			_path[1] = _to;
			return _path;
		} else {
			_path = new address[](3);
			_path[0] = _from;
			_path[1] = _WETH;
			_path[2] = _to;
			return _path;
		}
	}
}
