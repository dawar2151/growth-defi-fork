// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { Conversions } from "./Conversions.sol";
import { CompoundLendingMarketAbstraction } from "./CompoundLendingMarketAbstraction.sol";
import { GCTokenBase } from "./GCTokenBase.sol";

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
}

contract gcDAI is Addresses, Conversions, GCTokenBase, GLeveragedReserveManager
{
	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 18, GRO, cDAI)
		GLeveragedReserveManager(COMP, cUSDC) public
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
