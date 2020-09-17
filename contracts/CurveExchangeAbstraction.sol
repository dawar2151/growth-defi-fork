// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { Transfers } from "./Transfers.sol";
import { Swap } from "./interop/Curve.sol";

contract CurveExchangeAbstraction is Addresses, Transfers
{
	function _calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		address _swap = Curve_COMPOUND;
		int128 _i = Swap(_swap).underlying_coins(0) == _from ? 0 : 1;
		int128 _j = Swap(_swap).underlying_coins(0) == _to ? 0 : 1;
		require(Swap(_swap).underlying_coins(_i) == _from);
		require(Swap(_swap).underlying_coins(_j) == _to);
		if (_inputAmount == 0) return 0;
		return Swap(_swap).get_dy_underlying(_i, _j, _inputAmount);
	}

	function _calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		address _swap = Curve_COMPOUND;
		int128 _i = Swap(_swap).underlying_coins(0) == _from ? 0 : 1;
		int128 _j = Swap(_swap).underlying_coins(0) == _to ? 0 : 1;
		require(Swap(_swap).underlying_coins(_i) == _from);
		require(Swap(_swap).underlying_coins(_j) == _to);
		if (_outputAmount == 0) return 0;
		return Swap(_swap).get_dx_underlying(_i, _j, _outputAmount);
	}

	function _convertBalance(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		address _swap = Curve_COMPOUND;
		int128 _i = Swap(_swap).underlying_coins(0) == _from ? 0 : 1;
		int128 _j = Swap(_swap).underlying_coins(0) == _to ? 0 : 1;
		require(Swap(_swap).underlying_coins(_i) == _from);
		require(Swap(_swap).underlying_coins(_j) == _to);
		if (_inputAmount == 0) return 0;
		uint256 _balanceBefore = _getBalance(_to);
		_approveFunds(_from, Curve_COMPOUND, _inputAmount);
		Swap(_swap).exchange_underlying(_i, _j, _inputAmount, _minOutputAmount);
		uint256 _balanceAfter = _getBalance(_to);
		return _balanceAfter - _balanceBefore;
	}
}
