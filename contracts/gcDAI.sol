// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { Transfers } from "./Transfers.sol";
import { CompoundLendingMarketAbstraction, GCTokenBase } from "./GCTokenBase.sol";

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

contract UniswapV2ExchangeAbstraction is Transfers
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
	function _calcConversionDAIToUSDCGivenDAI(uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		address _swap = Addresses.Curve_COMPOUND;
		return Swap(_swap).get_dy_underlying(0, 1, _inputAmount);
	}

	function _calcConversionDAIToUSDCGivenUSDC(uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		address _swap = Addresses.Curve_COMPOUND;
		return Swap(_swap).get_dx_underlying(0, 1, _outputAmount);
	}

	function _calcConversionUSDCToDAIGivenUSDC(uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		address _swap = Addresses.Curve_COMPOUND;
		return Swap(_swap).get_dy_underlying(1, 0, _inputAmount);
	}

	function _calcConversionUSDCToDAIGivenDAI(uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		address _swap = Addresses.Curve_COMPOUND;
		return Swap(_swap).get_dx_underlying(1, 0, _outputAmount);
	}

	function _convertFundsUSDCToDAI(uint256 _amount) internal
	{
		address _swap = Addresses.Curve_COMPOUND;
		address _token = Swap(_swap).underlying_coins(1);
		_approveFunds(_token, _swap, _amount);
		Swap(_swap).exchange_underlying(1, 0, _amount, 0);
	}

	function _convertFundsDAIToUSDC(uint256 _amount) internal
	{
		address _swap = Addresses.Curve_COMPOUND;
		address _token = Swap(_swap).underlying_coins(0);
		_approveFunds(_token, _swap, _amount);
		Swap(_swap).exchange_underlying(0, 1, _amount, 0);
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

contract GLeveragedReserveManager is CompoundLendingMarketAbstraction
{
	uint256 constant LEVERAGE_ADJUSTMENT_AMOUNT = 1000e18; // $1,000
	uint256 constant IDEAL_COLLATERALIZATION_RATIO = 88e16; // 88% of 75% = 66%
	uint256 constant LIMIT_COLLATERALIZATION_RATIO = 92e16; // 92% of 75% = 69%

	address public immutable miningToken;
	address public immutable leverageToken;
	address public immutable borrowToken;

	bool public leverageEnabled = false;
	uint256 public leverageAdjustmentAmount = LEVERAGE_ADJUSTMENT_AMOUNT;
	uint256 public idealCollateralizationRatio = IDEAL_COLLATERALIZATION_RATIO;
	uint256 public limitCollateralizationRatio = LIMIT_COLLATERALIZATION_RATIO;

	constructor (address _miningToken, address _leverageToken) internal
	{
		miningToken = _miningToken;
		leverageToken = _leverageToken;
		borrowToken = _getUnderlyingToken(_leverageToken);
	}

	function _setLeverageEnabled(bool _leverageEnabled) internal
	{
		leverageEnabled = _leverageEnabled;
	}

	function _setLeverageAdjustmentAmount(uint256 _leverageAdjustmentAmount) internal
	{
		require(_leverageAdjustmentAmount > 0, "invalid amount");
		leverageAdjustmentAmount = _leverageAdjustmentAmount;
	}

	function _setIdealCollateralizationRatio(uint256 _idealCollateralizationRatio) internal
	{
		require(_idealCollateralizationRatio >= 5e16, "invalid ratio");
		require(_idealCollateralizationRatio + 5e16 <= limitCollateralizationRatio, "invalid ratio gap");
		idealCollateralizationRatio = _idealCollateralizationRatio;
	}

	function _setLimitCollateralizationRatio(uint256 _limitCollateralizationRatio) internal
	{
		require(_limitCollateralizationRatio <= 95e16, "invalid ratio");
		require(idealCollateralizationRatio + 5e16 <= _limitCollateralizationRatio, "invalid ratio gap");
		limitCollateralizationRatio = _limitCollateralizationRatio;
	}

	function _increaseLeverageLimited(uint256 _amount) internal returns (bool _success)
	{
		return _increaseLeverage(_min(_amount, leverageAdjustmentAmount));
	}

	function _decreaseLeverageLimited(uint256 _amount) internal returns (bool _success)
	{
		return _decreaseLeverage(_min(_amount, leverageAdjustmentAmount));
	}

	function _increaseLeverage(uint256 _amount) internal virtual returns (bool _success) { }
	function _decreaseLeverage(uint256 _amount) internal virtual returns (bool _success) { }

	function _calcIdealAmount(uint256 _amount, uint256 _collateralRatio) internal view returns (uint256 _idealAmount)
	{
		return _amount.mul(_collateralRatio).div(1e18).mul(idealCollateralizationRatio).div(1e18);
	}

	function _calcLimitAmount(uint256 _amount, uint256 _collateralRatio) internal view returns (uint256 _limitAmount)
	{
		return _amount.mul(_collateralRatio).div(1e18).mul(limitCollateralizationRatio).div(1e18);
	}

	function _min(uint256 _amount1, uint256 _amount2) internal pure returns (uint256 _minAmount)
	{
		return _amount1 < _amount2 ? _amount1 : _amount2;
	}
}

contract gcDAI is Conversions, GCTokenBase, GLeveragedReserveManager
{
	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 18, Addresses.GRO, Addresses.cDAI)
		GLeveragedReserveManager(Addresses.COMP, Addresses.cUSDC) public
	{
	}

	function totalReserve() public view override returns (uint256 _totalReserve)
	{
		return _calcCostFromUnderlyingCost(totalReserveUnderlying(), _getExchangeRate(reserveToken));
	}

	function totalReserveUnderlying() public view override returns (uint256 _totalReserveUnderlying)
	{
		uint256 _lendingReserveUnderlying = lendingReserveUnderlying();
		uint256 _borrowingReserveUnderlying = borrowingReserveUnderlying();
		if (_lendingReserveUnderlying < _borrowingReserveUnderlying) return 0;
		return _lendingReserveUnderlying.sub(_borrowingReserveUnderlying);
	}

	function lendingReserveUnderlying() public view returns (uint256 _lendingReserveUnderlying)
	{
		return _getLendAmount(reserveToken);
	}

	function borrowingReserveUnderlying() public view returns (uint256 _borrowingReserveUnderlying)
	{
		return _calcConversionDAIToUSDCGivenUSDC(_getBorrowAmount(leverageToken));
	}

	function setLeverageEnabled(bool _leverageEnabled) public onlyOwner
	{
		_setLeverageEnabled(_leverageEnabled);
	}

	function setLeverageAdjustmentAmount(uint256 _leverageAdjustmentAmount) public onlyOwner
	{
		_setLeverageAdjustmentAmount(_leverageAdjustmentAmount);
	}

	function setIdealCollateralizationRatio(uint256 _idealCollateralizationRatio) public onlyOwner
	{
		_setIdealCollateralizationRatio(_idealCollateralizationRatio);
	}

	function setLimitCollateralizationRatio(uint256 _limitCollateralizationRatio) public onlyOwner
	{
		_setLimitCollateralizationRatio(_limitCollateralizationRatio);
	}

	function _prepareWithdrawal(uint256 _cost) internal override {
		uint256 _requiredAmount = _calcUnderlyingCostFromCost(_cost, _fetchExchangeRate(reserveToken));
		uint256 _availableAmount = _getAvailableAmount(reserveToken);
		if (_requiredAmount > _availableAmount) {
			require(_decreaseLeverage(_requiredAmount.sub(_availableAmount)), "unliquid market, try again later");
		}
	}

	function _adjustReserve() internal override {
		_gulpMiningAssets();
		_adjustLeverage();
	}

	function _gulpMiningAssets() internal
	{
		_convertFundsCOMPToDAI(_getBalance(miningToken));
		_lend(reserveToken, _getBalance(underlyingToken));
	}

	function _adjustLeverage() internal returns (bool _success)
	{
		uint256 _borrowingAmount = _calcConversionDAIToUSDCGivenDAI(_fetchBorrowAmount(leverageToken));
		if (!leverageEnabled) return _decreaseLeverageLimited(_borrowingAmount);
		uint256 _lendingAmount = _fetchLendAmount(reserveToken);
		uint256 _limitAmount = _calcLimitAmount(_lendingAmount, _getCollateralRatio(reserveToken));
		if (_borrowingAmount > _limitAmount) return _decreaseLeverageLimited(_borrowingAmount.sub(_limitAmount));
		uint256 _idealAmount = _calcIdealAmount(_lendingAmount, _getCollateralRatio(reserveToken));
		if (_borrowingAmount < _idealAmount) return _increaseLeverageLimited(_idealAmount.sub(_borrowingAmount));
		return true;
	}

	function _increaseLeverage(uint256 _amount) internal override returns (bool _success)
	{
		_success = _borrow(leverageToken, _min(_calcConversionDAIToUSDCGivenDAI(_amount), _getAvailableAmount(leverageToken)));
		if (!_success) return false;
		_convertFundsUSDCToDAI(_getBalance(borrowToken));
		_repay(leverageToken, _min(_getBalance(borrowToken), _getBorrowAmount(leverageToken)));
		_convertFundsUSDCToDAI(_getBalance(borrowToken));
		return _lend(reserveToken, _getBalance(underlyingToken));
	}

	function _decreaseLeverage(uint256 _amount) internal override returns (bool _success)
	{
		_success = _redeem(reserveToken, _min(_calcConversionDAIToUSDCGivenUSDC(_calcConversionUSDCToDAIGivenDAI(_amount)), _getAvailableAmount(reserveToken)));
		if (!_success) return false;
		_convertFundsDAIToUSDC(_getBalance(underlyingToken));
		_success = _repay(leverageToken, _min(_getBalance(borrowToken), _getBorrowAmount(leverageToken)));
		_convertFundsUSDCToDAI(_getBalance(borrowToken));
		_lend(reserveToken, _getBalance(underlyingToken));
		return _success;
	}
}
