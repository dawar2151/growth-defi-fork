// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { CompoundLendingMarketAbstraction } from "./CompoundLendingMarketAbstraction.sol";
import { UniswapV2ExchangeAbstraction } from "./UniswapV2ExchangeAbstraction.sol";

contract GCLeveragedReserveManager is CompoundLendingMarketAbstraction, UniswapV2ExchangeAbstraction
{
	uint256 constant DEFAULT_IDEAL_COLLATERALIZATION_RATIO = 88e16; // 88% of 75% = 66%
	uint256 constant DEFAULT_LIMIT_COLLATERALIZATION_RATIO = 92e16; // 92% of 75% = 69%

	address private immutable miningToken;
	address private immutable reserveToken;
	address private immutable underlyingToken;
	address private immutable leverageToken;
	address private immutable borrowToken;

	bool private leverageEnabled = false;
	uint256 private leverageAdjustmentAmount;
	uint256 private idealCollateralizationRatio = DEFAULT_IDEAL_COLLATERALIZATION_RATIO;
	uint256 private limitCollateralizationRatio = DEFAULT_LIMIT_COLLATERALIZATION_RATIO;

	constructor (address _miningToken, address _reserveToken, address _leverageToken, uint256 _leverageAdjustmentAmount) internal
	{
		miningToken = _miningToken;
		reserveToken = _reserveToken;
		underlyingToken = _getUnderlyingToken(_reserveToken);
		leverageToken = _leverageToken;
		borrowToken = _getUnderlyingToken(_leverageToken);
		leverageAdjustmentAmount = _leverageAdjustmentAmount;
		_safeEnter(_reserveToken);
	}

	function _getLeverageEnabled() internal view returns (bool _leverageEnabled)
	{
		return leverageEnabled;
	}

	function _getLeverageAdjustmentAmount() internal view returns (uint256 _leverageAdjustmentAmount)
	{
		return leverageAdjustmentAmount;
	}

	function _getIdealCollateralizationRatio() internal view returns (uint256 _idealCollateralizationRatio)
	{
		return idealCollateralizationRatio;
	}

	function _getLimitCollateralizationRatio() internal view returns (uint256 _limitCollateralizationRatio)
	{
		return limitCollateralizationRatio;
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

	function _gulpMiningAssets() internal returns (bool _success)
	{
		_convertMiningToUnderlying(_getBalance(miningToken));
		return _lend(reserveToken, _getBalance(underlyingToken));
	}

	function _adjustLeverage() internal returns (bool _success)
	{
		uint256 _borrowingAmount = _calcConversionUnderlyingToBorrowGivenBorrow(_fetchBorrowAmount(leverageToken));
		if (!leverageEnabled) return _decreaseLeverageLimited(_borrowingAmount);
		uint256 _lendingAmount = _fetchLendAmount(reserveToken);
		uint256 _limitAmount = _calcLimitAmount(_lendingAmount, _getCollateralRatio(reserveToken));
		if (_borrowingAmount > _limitAmount) return _decreaseLeverageLimited(_borrowingAmount.sub(_limitAmount));
		uint256 _idealAmount = _calcIdealAmount(_lendingAmount, _getCollateralRatio(reserveToken));
		if (_borrowingAmount < _idealAmount) return _increaseLeverageLimited(_idealAmount.sub(_borrowingAmount));
		return true;
	}

	function _calcIdealAmount(uint256 _amount, uint256 _collateralRatio) internal view returns (uint256 _idealAmount)
	{
		return _amount.mul(_collateralRatio).div(1e18).mul(idealCollateralizationRatio).div(1e18);
	}

	function _calcLimitAmount(uint256 _amount, uint256 _collateralRatio) internal view returns (uint256 _limitAmount)
	{
		return _amount.mul(_collateralRatio).div(1e18).mul(limitCollateralizationRatio).div(1e18);
	}

	function _getAvailableUnderlying() internal view returns (uint256 _availableUnderlying)
	{
		uint256 _lendingAmount = _getLendAmount(reserveToken);
		uint256 _limitAmount = _calcLimitAmount(_lendingAmount, _getCollateralRatio(reserveToken));
		return _getAvailableAmount(reserveToken, _limitAmount);
	}

	function _getAvailableBorrow() internal view returns (uint256 _availableBorrow)
	{
		return _calcConversionUnderlyingToBorrowGivenUnderlying(_getAvailableUnderlying());
	}

	function _increaseLeverageLimited(uint256 _amount) internal returns (bool _success)
	{
		return _increaseLeverage(_min(_amount, leverageAdjustmentAmount));
	}

	function _decreaseLeverageLimited(uint256 _amount) internal returns (bool _success)
	{
		return _decreaseLeverage(_min(_amount, leverageAdjustmentAmount));
	}

	function _increaseLeverage(uint256 _amount) internal returns (bool _success)
	{
		_success = _borrow(leverageToken, _min(_calcConversionUnderlyingToBorrowGivenUnderlying(_amount), _getAvailableBorrow()));
		if (!_success) return false;
		_convertBorrowToUnderlying(_getBalance(borrowToken));
		_repay(leverageToken, _min(_getBalance(borrowToken), _getBorrowAmount(leverageToken)));
		_convertBorrowToUnderlying(_getBalance(borrowToken));
		return _lend(reserveToken, _getBalance(underlyingToken));
	}

	function _decreaseLeverage(uint256 _amount) internal returns (bool _success)
	{
		_success = _redeem(reserveToken, _min(_calcConversionUnderlyingToBorrowGivenBorrow(_calcConversionBorrowToUnderlyingGivenUnderlying(_amount)), _getAvailableUnderlying()));
		if (!_success) return false;
		_convertUnderlyingToBorrow(_getBalance(underlyingToken));
		_success = _repay(leverageToken, _min(_getBalance(borrowToken), _getBorrowAmount(leverageToken)));
		_convertBorrowToUnderlying(_getBalance(borrowToken));
		_lend(reserveToken, _getBalance(underlyingToken));
		return _success;
	}

	function _calcConversionUnderlyingToBorrowGivenUnderlying(uint256 _inputAmount) internal view virtual returns (uint256 _outputAmount)
	{
		return _calcConversionOutputFromInput(underlyingToken, borrowToken, _inputAmount);
	}

	function _calcConversionUnderlyingToBorrowGivenBorrow(uint256 _outputAmount) internal view virtual returns (uint256 _inputAmount)
	{
		return _calcConversionInputFromOutput(underlyingToken, borrowToken, _outputAmount);
	}

	function _calcConversionBorrowToUnderlyingGivenUnderlying(uint256 _outputAmount) internal view virtual returns (uint256 _inputAmount)
	{
		return _calcConversionInputFromOutput(borrowToken, underlyingToken, _outputAmount);
	}

	function _convertMiningToUnderlying(uint256 _inputAmount) internal virtual
	{
		_convertBalance(miningToken, underlyingToken, _inputAmount, 0);
	}

	function _convertBorrowToUnderlying(uint256 _inputAmount) internal virtual
	{
		_convertBalance(borrowToken, underlyingToken, _inputAmount, 0);
	}

	function _convertUnderlyingToBorrow(uint256 _inputAmount) internal virtual
	{
		_convertBalance(underlyingToken, borrowToken, _inputAmount, 0);
	}
}
