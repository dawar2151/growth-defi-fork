// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { Transfers } from "./Transfers.sol";
import { GCTokenBase } from "./GCTokenBase.sol";

import { Swap } from "./interop/Curve.sol";
import { Router02 } from "./interop/UniswapV2.sol";

contract CurveExchangeAbstraction is Transfers
{
	function _C_calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		Swap _swap = Swap(Addresses.Curve_COMPOUND);
		int128 _i = _swap.underlying_coins(0) == _from ? 0 : 1;
		int128 _j = _swap.underlying_coins(0) == _to ? 0 : 1;
		require(_swap.underlying_coins(_i) == _from);
		require(_swap.underlying_coins(_j) == _to);
		if (_inputAmount == 0) return 0;
		return _swap.get_dy_underlying(_i, _j, _inputAmount);
	}

	function _C_calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		Swap _swap = Swap(Addresses.Curve_COMPOUND);
		int128 _i = _swap.underlying_coins(0) == _from ? 0 : 1;
		int128 _j = _swap.underlying_coins(0) == _to ? 0 : 1;
		require(_swap.underlying_coins(_i) == _from);
		require(_swap.underlying_coins(_j) == _to);
		if (_outputAmount == 0) return 0;
		return _swap.get_dx_underlying(_i, _j, _outputAmount);
	}

	function _C_convertBalance(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		Swap _swap = Swap(Addresses.Curve_COMPOUND);
		int128 _i = _swap.underlying_coins(0) == _from ? 0 : 1;
		int128 _j = _swap.underlying_coins(0) == _to ? 0 : 1;
		require(_swap.underlying_coins(_i) == _from);
		require(_swap.underlying_coins(_j) == _to);
		if (_inputAmount == 0) return 0;
		uint256 _balanceBefore = _getBalance(_to);
		_approveFunds(_from, Addresses.Curve_COMPOUND, _inputAmount);
		_swap.exchange_underlying(_i, _j, _inputAmount, _minOutputAmount);
		uint256 _balanceAfter = _getBalance(_to);
		return _balanceAfter - _balanceBefore;
	}
}

contract UniswapExchangeAbstraction is Transfers
{
	function _U_calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		Router02 _router = Router02(Addresses.UniswapV2_ROUTER02);
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = _router.WETH();
		_path[2] = _to;
		return _router.getAmountsOut(_inputAmount, _path)[2];
	}

	function _U_calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		Router02 _router = Router02(Addresses.UniswapV2_ROUTER02);
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = _router.WETH();
		_path[2] = _to;
		return _router.getAmountsIn(_outputAmount, _path)[0];
	}

	function _U_convertBalance(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		Router02 _router = Router02(Addresses.UniswapV2_ROUTER02);
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = _router.WETH();
		_path[2] = _to;
		_approveFunds(_from, Addresses.UniswapV2_ROUTER02, _inputAmount);
		return _router.swapExactTokensForTokens(_inputAmount, _minOutputAmount, _path, address(this), uint256(-1))[2];
	}
}

contract Conversions is Transfers
{
	function _convertFundsUSDCToDAI(uint256 _amount) internal
	{
		address _swap = Addresses.Curve_COMPOUND;
		address _token = Swap(_swap).underlying_coins(1);
		_approveFunds(_token, _swap, _amount);
		Swap(_swap).exchange_underlying(1, 0, _amount, 0);
	}

	function _convertFundsCOMPToDAI(uint256 _amount) internal
	{
		if (_amount == 0) return;
		address _router = Addresses.UniswapV2_ROUTER02;
		address _token = Addresses.COMP;
		address[] memory _path = new address[](3);
		_path[0] = _token;
		_path[1] = Router02(_router).WETH();
		_path[2] = Addresses.DAI;
		_approveFunds(_token, _router, _amount);
		Router02(_router).swapExactTokensForTokens(_amount, 0, _path, address(this), block.timestamp);
	}
}

contract gcDAI is GCTokenBase, Conversions
{
	uint256 constant IDEAL_COLLATERALIZATION_RATIO = 65e16; // 65%
	uint256 constant LIMIT_COLLATERALIZATION_RATIO = 70e16; // 70%
	uint256 constant LIMIT_ADJUSTMENT_AMOUNT = 1000e18; // $1,000

	address public immutable bonusToken;
	address public immutable borrowToken;
	address public immutable borrowUnderlyingToken;

	bool private enableBorrowStrategy = false;

	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 18, Addresses.GRO, Addresses.cDAI) public
	{
		bonusToken = Addresses.COMP;
		borrowToken = Addresses.cUSDC;
		borrowUnderlyingToken = _getUnderlyingToken(Addresses.cUSDC);
	}
/*
	function totalReserve() public override returns (uint256 _totalReserve)
	{
		return _calcTotalReserve();
	}

	function setEnableBorrowStrategy(bool _enableBorrowStrategy) public onlyOwner
	{
		enableBorrowStrategy = _enableBorrowStrategy;
	}

	function _gulpBonusAsset() internal
	{
		uint256 _bonusAmount = _getBalance(bonusToken);
		if (_bonusAmount == 0) return;
		uint256 _underlyingCost = _U_calcConversionOutputFromInput(bonusToken, underlyingToken, _bonusAmount);
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _getExchangeRate(reserveToken, underlyingToken));
		_U_convertBalance(bonusToken, underlyingToken, _bonusAmount, _underlyingCost);
		_lend(reserveToken, _cost, underlyingToken, _underlyingCost);
	}

	function _calcTotalReserve() internal returns (uint256 _totalReserve)
	{
		uint256 _cost = _getBalance(reserveToken);
		uint256 _underlyingCost = _calcUnderlyingCostFromCost(_cost, _getExchangeRate(reserveToken, underlyingToken));

		address _borrowUnderlyingToken = _getUnderlyingToken(borrowToken);
		uint256 _borrowAmount = _getBorrowAmount(borrowToken);
		uint256 _borrowedUnderlyingCost = _C_calcConversionInputFromOutput(underlyingToken, _borrowUnderlyingToken, _borrowAmount);

		uint256 _totalReserveUnderlying = _underlyingCost.sub(_borrowedUnderlyingCost);

		return _calcCostFromUnderlyingCost(_totalReserveUnderlying, _getExchangeRate(reserveToken, underlyingToken));
	}

	function _ensureRedeemCost(uint256 _cost) internal
	{
		uint256 _underlyingCost = _calcUnderlyingCostFromCost(_cost, _getExchangeRate(reserveToken, underlyingToken));
		uint256 _availableUnderlyingCost = _getRedeemAmount(reserveToken);
		if (_underlyingCost > _availableUnderlyingCost) {
			uint256 _requiredUnderlyingCost = _underlyingCost.sub(_availableUnderlyingCost);
			_decreaseDebt(_requiredUnderlyingCost);
		}
	}

	function _increaseDebt(uint256 _underlyingCost) internal
	{
		uint256 _borrowCost = _C_calcConversionOutputFromInput(underlyingToken, borrowUnderlyingToken, _underlyingCost);
		_underlyingCost = _C_calcConversionOutputFromInput(borrowUnderlyingToken, underlyingToken, _borrowCost);
		_borrow(borrowToken, borrowUnderlyingToken, _borrowCost);
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _getExchangeRate(reserveToken, underlyingToken));
		_U_convertBalance(borrowUnderlyingToken, underlyingToken, _borrowCost, _underlyingCost);
		_lend(reserveToken, _cost, underlyingToken, _underlyingCost);
	}

	function _decreaseDebt(uint256 _underlyingCost) internal
	{
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _getExchangeRate(reserveToken, underlyingToken));
		uint256 _borrowCost = _C_calcConversionOutputFromInput(underlyingToken, borrowUnderlyingToken, _underlyingCost);
		_redeem(reserveToken, _cost, underlyingToken, _underlyingCost);
		_U_convertBalance(underlyingToken, borrowUnderlyingToken, _underlyingCost, _borrowCost);
		_repay(borrowToken, borrowUnderlyingToken, _borrowCost);
	}

	function _adjustBorrowStrategy() internal
	{
		uint256 _cost = _getBalance(reserveToken);
		uint256 _underlyingCost = _calcUnderlyingCostFromCost(_cost, _getExchangeRate(reserveToken, underlyingToken));

		uint256 _borrowAmount = _getBorrowAmount(borrowToken);
		uint256 _borrowedUnderlyingCost = _C_calcConversionInputFromOutput(underlyingToken, borrowUnderlyingToken, _borrowAmount);

		uint256 _idealUnderlyingCost = _underlyingCost.mul(IDEAL_COLLATERALIZATION_RATIO).div(1e18);
		uint256 _limitUnderlyingCost = _underlyingCost.mul(LIMIT_COLLATERALIZATION_RATIO).div(1e18);
		bool _overCollateralized = _borrowedUnderlyingCost < _idealUnderlyingCost;
		bool _underCollateralized = _borrowedUnderlyingCost > _limitUnderlyingCost;

		if (enableBorrowStrategy && _overCollateralized) {
			uint256 _incrementUnderlyingCost = _idealUnderlyingCost.sub(_borrowedUnderlyingCost);
			if (_incrementUnderlyingCost > LIMIT_ADJUSTMENT_AMOUNT) _incrementUnderlyingCost = LIMIT_ADJUSTMENT_AMOUNT;
			_increaseDebt(_incrementUnderlyingCost);
		}
		else
		if (!enableBorrowStrategy) {
			uint256 _decrementUnderlyingCost = _borrowedUnderlyingCost;
			if (_decrementUnderlyingCost > LIMIT_ADJUSTMENT_AMOUNT) _decrementUnderlyingCost = LIMIT_ADJUSTMENT_AMOUNT;
			_decreaseDebt(_decrementUnderlyingCost);
		}
		else
		if (_underCollateralized) {
			uint256 _decrementUnderlyingCost = _borrowedUnderlyingCost.sub(_idealUnderlyingCost);
			if (_decrementUnderlyingCost > LIMIT_ADJUSTMENT_AMOUNT) _decrementUnderlyingCost = LIMIT_ADJUSTMENT_AMOUNT;
			_decreaseDebt(_decrementUnderlyingCost);
		}
	}
*/
}
