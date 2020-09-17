// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { Transfers } from "./Transfers.sol";
import { Router02 } from "./interop/UniswapV2.sol";

contract UniswapV2ExchangeAbstraction is Addresses, Transfers
{
	function _U_calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		Router02 _router = Router02(UniswapV2_ROUTER02);
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = _router.WETH();
		_path[2] = _to;
		return _router.getAmountsOut(_inputAmount, _path)[2];
	}

	function _U_calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		Router02 _router = Router02(UniswapV2_ROUTER02);
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = _router.WETH();
		_path[2] = _to;
		return _router.getAmountsIn(_outputAmount, _path)[0];
	}

	function _U_convertBalance(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		Router02 _router = Router02(UniswapV2_ROUTER02);
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = _router.WETH();
		_path[2] = _to;
		_approveFunds(_from, UniswapV2_ROUTER02, _inputAmount);
		return _router.swapExactTokensForTokens(_inputAmount, _minOutputAmount, _path, address(this), uint256(-1))[2];
	}
}
