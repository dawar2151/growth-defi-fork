// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { Transfers } from "./Transfers.sol";
import { Swap } from "./interop/Curve.sol";

contract CurveExchangeAbstraction is Addresses, Transfers
{
	function _C_calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		Swap _swap = Swap(Curve_COMPOUND);
		int128 _i = _swap.underlying_coins(0) == _from ? 0 : 1;
		int128 _j = _swap.underlying_coins(0) == _to ? 0 : 1;
		require(_swap.underlying_coins(_i) == _from);
		require(_swap.underlying_coins(_j) == _to);
		if (_inputAmount == 0) return 0;
		return _swap.get_dy_underlying(_i, _j, _inputAmount);
	}

	function _C_calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		Swap _swap = Swap(Curve_COMPOUND);
		int128 _i = _swap.underlying_coins(0) == _from ? 0 : 1;
		int128 _j = _swap.underlying_coins(0) == _to ? 0 : 1;
		require(_swap.underlying_coins(_i) == _from);
		require(_swap.underlying_coins(_j) == _to);
		if (_outputAmount == 0) return 0;
		return _swap.get_dx_underlying(_i, _j, _outputAmount);
	}

	function _C_convertBalance(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		Swap _swap = Swap(Curve_COMPOUND);
		int128 _i = _swap.underlying_coins(0) == _from ? 0 : 1;
		int128 _j = _swap.underlying_coins(0) == _to ? 0 : 1;
		require(_swap.underlying_coins(_i) == _from);
		require(_swap.underlying_coins(_j) == _to);
		if (_inputAmount == 0) return 0;
		uint256 _balanceBefore = _getBalance(_to);
		_approveFunds(_from, Curve_COMPOUND, _inputAmount);
		_swap.exchange_underlying(_i, _j, _inputAmount, _minOutputAmount);
		uint256 _balanceAfter = _getBalance(_to);
		return _balanceAfter - _balanceBefore;
	}
}


