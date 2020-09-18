// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { G } from "./G.sol";

library GCLeveragedReserveManager
{
	using SafeMath for uint256;
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	uint256 constant DEFAULT_IDEAL_COLLATERALIZATION_RATIO = 88e16; // 88% of 75% = 66%
	uint256 constant DEFAULT_LIMIT_COLLATERALIZATION_RATIO = 92e16; // 92% of 75% = 69%

	struct Self {
		address miningToken;
		address reserveToken;
		address underlyingToken;
		address leverageToken;
		address borrowToken;

		bool leverageEnabled;
		uint256 leverageAdjustmentAmount;
		uint256 idealCollateralizationRatio;
		uint256 limitCollateralizationRatio;
	}

	function init(Self storage _self, address _miningToken, address _reserveToken, address _leverageToken, uint256 _leverageAdjustmentAmount) public
	{
		_self.miningToken = _miningToken;
		_self.reserveToken = _reserveToken;
		_self.underlyingToken = G.getUnderlyingToken(_reserveToken);
		_self.leverageToken = _leverageToken;
		_self.borrowToken = G.getUnderlyingToken(_leverageToken);

		_self.leverageEnabled = false;
		_self.leverageAdjustmentAmount = _leverageAdjustmentAmount;
		_self.idealCollateralizationRatio = DEFAULT_IDEAL_COLLATERALIZATION_RATIO;
		_self.limitCollateralizationRatio = DEFAULT_LIMIT_COLLATERALIZATION_RATIO;

		G.safeEnter(_reserveToken);
	}

	function setLeverageEnabled(Self storage _self, bool _leverageEnabled) public
	{
		_self.leverageEnabled = _leverageEnabled;
	}

	function setLeverageAdjustmentAmount(Self storage _self, uint256 _leverageAdjustmentAmount) public
	{
		require(_leverageAdjustmentAmount > 0, "invalid amount");
		_self.leverageAdjustmentAmount = _leverageAdjustmentAmount;
	}

	function setIdealCollateralizationRatio(Self storage _self, uint256 _idealCollateralizationRatio) public
	{
		require(_idealCollateralizationRatio >= 5e16, "invalid ratio");
		require(_idealCollateralizationRatio + 5e16 <= _self.limitCollateralizationRatio, "invalid ratio gap");
		_self.idealCollateralizationRatio = _idealCollateralizationRatio;
	}

	function setLimitCollateralizationRatio(Self storage _self, uint256 _limitCollateralizationRatio) public
	{
		require(_limitCollateralizationRatio <= 95e16, "invalid ratio");
		require(_self.idealCollateralizationRatio + 5e16 <= _limitCollateralizationRatio, "invalid ratio gap");
		_self.limitCollateralizationRatio = _limitCollateralizationRatio;
	}

	function gulpMiningAssets(Self storage _self) public returns (bool _success)
	{
		uint256 _balance = G.getBalance(_self.miningToken);
		uint256 _convAmount = _self._calcConversionUnderlyingToMiningGivenMining(_balance);
		uint256 _maxAmount = G.min(_convAmount, _self.leverageAdjustmentAmount);
		uint256 _amount = _convAmount > 0 ? G.getBalance(_self.miningToken).mul(_maxAmount).div(_convAmount) : 0;
		_self._convertMiningToUnderlying(_amount);
		return G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
	}

	function adjustLeverage(Self storage _self) public returns (bool _success)
	{
		uint256 _borrowingAmount = _self._calcConversionUnderlyingToBorrowGivenBorrow(G.fetchBorrowAmount(_self.leverageToken));
		if (!_self.leverageEnabled) return _self._decreaseLeverageLimited(_borrowingAmount);
		uint256 _lendingAmount = G.fetchLendAmount(_self.reserveToken);
		uint256 _limitAmount = _self._calcLimitAmount(_lendingAmount, G.getCollateralRatio(_self.reserveToken));
		if (_borrowingAmount > _limitAmount) return _self._decreaseLeverageLimited(_borrowingAmount.sub(_limitAmount));
		uint256 _idealAmount = _self._calcIdealAmount(_lendingAmount, G.getCollateralRatio(_self.reserveToken));
		if (_borrowingAmount < _idealAmount) return _self._increaseLeverageLimited(_idealAmount.sub(_borrowingAmount));
		return true;
	}

	function decreaseLeverage(Self storage _self, uint256 _amount) public returns (bool _success)
	{
		return _self._decreaseLeverage(_amount);
	}

	function calcConversionUnderlyingToBorrowGivenBorrow(Self storage _self, uint256 _outputAmount) public view returns (uint256 _inputAmount)
	{
		return _self._calcConversionUnderlyingToBorrowGivenBorrow(_outputAmount);
	}

	function getAvailableUnderlying(Self storage _self) public view returns (uint256 _availableUnderlying)
	{
		return _self._getAvailableUnderlying();
	}

	function _calcIdealAmount(Self storage _self, uint256 _amount, uint256 _collateralRatio) internal view returns (uint256 _idealAmount)
	{
		return _amount.mul(_collateralRatio).div(1e18).mul(_self.idealCollateralizationRatio).div(1e18);
	}

	function _calcLimitAmount(Self storage _self, uint256 _amount, uint256 _collateralRatio) internal view returns (uint256 _limitAmount)
	{
		return _amount.mul(_collateralRatio).div(1e18).mul(_self.limitCollateralizationRatio).div(1e18);
	}

	function _getAvailableUnderlying(Self storage _self) internal view returns (uint256 _availableUnderlying)
	{
		uint256 _lendingAmount = G.getLendAmount(_self.reserveToken);
		uint256 _limitAmount = _self._calcLimitAmount(_lendingAmount, G.getCollateralRatio(_self.reserveToken));
		return G.getAvailableAmount(_self.reserveToken, _limitAmount);
	}

	function _getAvailableBorrow(Self storage _self) internal view returns (uint256 _availableBorrow)
	{
		return _self._calcConversionUnderlyingToBorrowGivenUnderlying(_self._getAvailableUnderlying());
	}

	function _increaseLeverageLimited(Self storage _self, uint256 _amount) internal returns (bool _success)
	{
		return _self._increaseLeverage(G.min(_amount, _self.leverageAdjustmentAmount));
	}

	function _decreaseLeverageLimited(Self storage _self, uint256 _amount) internal returns (bool _success)
	{
		return _self._decreaseLeverage(G.min(_amount, _self.leverageAdjustmentAmount));
	}

	function _increaseLeverage(Self storage _self, uint256 _amount) internal returns (bool _success)
	{
		_success = G.borrow(_self.leverageToken, G.min(_self._calcConversionUnderlyingToBorrowGivenUnderlying(_amount), _self._getAvailableBorrow()));
		if (!_success) return false;
		_self._convertBorrowToUnderlying(G.getBalance(_self.borrowToken));
		G.repay(_self.leverageToken, G.min(G.getBalance(_self.borrowToken), G.getBorrowAmount(_self.leverageToken)));
		_self._convertBorrowToUnderlying(G.getBalance(_self.borrowToken));
		return G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
	}

	function _decreaseLeverage(Self storage _self, uint256 _amount) internal returns (bool _success)
	{
		_success = G.redeem(_self.reserveToken, G.min(_self._calcConversionUnderlyingToBorrowGivenBorrow(_self._calcConversionBorrowToUnderlyingGivenUnderlying(_amount)), _self._getAvailableUnderlying()));
		if (!_success) return false;
		_self._convertUnderlyingToBorrow(G.getBalance(_self.underlyingToken));
		_success = G.repay(_self.leverageToken, G.min(G.getBalance(_self.borrowToken), G.getBorrowAmount(_self.leverageToken)));
		_self._convertBorrowToUnderlying(G.getBalance(_self.borrowToken));
		G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
		return _success;
	}

	function _calcConversionUnderlyingToMiningGivenMining(Self storage _self, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		return G.calcConversionInputFromOutput(_self.underlyingToken, _self.miningToken, _outputAmount);
	}

	function _calcConversionUnderlyingToBorrowGivenUnderlying(Self storage _self, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		return G.calcConversionOutputFromInput(_self.underlyingToken, _self.borrowToken, _inputAmount);
	}

	function _calcConversionUnderlyingToBorrowGivenBorrow(Self storage _self, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		return G.calcConversionInputFromOutput(_self.underlyingToken, _self.borrowToken, _outputAmount);
	}

	function _calcConversionBorrowToUnderlyingGivenUnderlying(Self storage _self, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		return G.calcConversionInputFromOutput(_self.borrowToken, _self.underlyingToken, _outputAmount);
	}

	function _convertMiningToUnderlying(Self storage _self, uint256 _inputAmount) internal
	{
		G.convertFunds(_self.miningToken, _self.underlyingToken, _inputAmount, 0);
	}

	function _convertBorrowToUnderlying(Self storage _self, uint256 _inputAmount) internal
	{
		G.convertFunds(_self.borrowToken, _self.underlyingToken, _inputAmount, 0);
	}

	function _convertUnderlyingToBorrow(Self storage _self, uint256 _inputAmount) internal
	{
		G.convertFunds(_self.underlyingToken, _self.borrowToken, _inputAmount, 0);
	}
}
