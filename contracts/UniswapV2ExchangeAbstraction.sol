// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { Transfers } from "./Transfers.sol";
import { Router02 } from "./interop/UniswapV2.sol";

library UniswapV2ExchangeAbstraction
{
	function _calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		address _router = Addresses.UniswapV2_ROUTER02;
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = Router02(_router).WETH();
		_path[2] = _to;
		return Router02(_router).getAmountsOut(_inputAmount, _path)[2];
	}

	function _calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		address _router = Addresses.UniswapV2_ROUTER02;
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = Router02(_router).WETH();
		_path[2] = _to;
		return Router02(_router).getAmountsIn(_outputAmount, _path)[0];
	}

	function _convertFunds(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		if (_inputAmount == 0) return 0;
		address _router = Addresses.UniswapV2_ROUTER02;
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = Router02(_router).WETH();
		_path[2] = _to;
		Transfers._approveFunds(_from, _router, _inputAmount);
		return Router02(_router).swapExactTokensForTokens(_inputAmount, _minOutputAmount, _path, address(this), uint256(-1))[2];
	}
}
