// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { G } from "./G.sol";

library GCLeveragedReserveManager
{
	using SafeMath for uint256;
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	uint256 constant DELEVERAGING_UNROLL_LIMIT = 10;
	uint256 constant MINIMUM_RATIO_GRANULARITY = 4e16; // 4%
	uint256 constant DEFAULT_IDEAL_COLLATERALIZATION_RATIO = 88e16; // 88% of 75% = 66%
	uint256 constant DEFAULT_LIMIT_COLLATERALIZATION_RATIO = 92e16; // 92% of 75% = 69%
	uint256 constant DEFAULT_COLLATERALIZATION_DEVIATION_RATIO = 1e16; // 1%

	struct Self {
		address miningToken;
		address reserveToken;
		address underlyingToken;

		uint256 miningMinGulpAmount;
		uint256 miningMaxGulpAmount;

		bool leverageEnabled;
		uint256 idealCollateralizationRatio;
		uint256 limitCollateralizationRatio;
		uint256 collateralizationDeviationRatio;
	}

	function init(Self storage _self, address _miningToken, address _reserveToken, uint256 _miningGulpAmount) public
	{
		_self.miningToken = _miningToken;
		_self.reserveToken = _reserveToken;
		_self.underlyingToken = G.getUnderlyingToken(_reserveToken);

		_self.miningMinGulpAmount = _miningGulpAmount;
		_self.miningMaxGulpAmount = _miningGulpAmount;

		_self.leverageEnabled = false;
		_self.idealCollateralizationRatio = DEFAULT_IDEAL_COLLATERALIZATION_RATIO;
		_self.limitCollateralizationRatio = DEFAULT_LIMIT_COLLATERALIZATION_RATIO;
		_self.collateralizationDeviationRatio = DEFAULT_COLLATERALIZATION_DEVIATION_RATIO;

		G.safeEnter(_reserveToken);
	}

	function setMiningGulpRange(Self storage _self, uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) public
	{
		require(_miningMinGulpAmount <= _miningMaxGulpAmount, "invalid range");
		_self.miningMinGulpAmount = _miningMinGulpAmount;
		_self.miningMaxGulpAmount = _miningMaxGulpAmount;
	}

	function setLeverageEnabled(Self storage _self, bool _leverageEnabled) public
	{
		_self.leverageEnabled = _leverageEnabled;
	}

	function setIdealCollateralizationRatio(Self storage _self, uint256 _idealCollateralizationRatio) public
	{
		require(_idealCollateralizationRatio >= MINIMUM_RATIO_GRANULARITY, "invalid ratio");
		require(_idealCollateralizationRatio + MINIMUM_RATIO_GRANULARITY <= _self.limitCollateralizationRatio, "invalid ratio gap");
		_self.idealCollateralizationRatio = _idealCollateralizationRatio;
	}

	function setLimitCollateralizationRatio(Self storage _self, uint256 _limitCollateralizationRatio) public
	{
		require(_limitCollateralizationRatio + MINIMUM_RATIO_GRANULARITY <= 1e18, "invalid ratio");
		require(_self.idealCollateralizationRatio + MINIMUM_RATIO_GRANULARITY <= _limitCollateralizationRatio, "invalid ratio gap");
		_self.limitCollateralizationRatio = _limitCollateralizationRatio;
	}

	function setCollateralizationDeviationRatio(Self storage _self, uint256 _collateralizationDeviationRatio) public
	{
		require(_collateralizationDeviationRatio <= MINIMUM_RATIO_GRANULARITY, "invalid ratio");
		_self.collateralizationDeviationRatio = _collateralizationDeviationRatio;
	}

	function ensureLiquidity(Self storage _self, uint256 _requiredAmount) public returns (bool _success)
	{
		uint256 _availableAmount = _self._getAvailableUnderlying();
		for (uint256 _i; _i < DELEVERAGING_UNROLL_LIMIT; _i++) {
			if (_requiredAmount <= _availableAmount) return true;
			_success = _self._decreaseLeverage(_requiredAmount.sub(_availableAmount));
			if (!_success) return false;
			uint256 _newAvailableAmount = _self._getAvailableUnderlying();
			if (_newAvailableAmount <= _availableAmount) return false;
			_availableAmount = _newAvailableAmount;
		}
		return false;
	}

	function gulpMiningAssets(Self storage _self) public returns (bool _success)
	{
		uint256 _miningAmount = G.getBalance(_self.miningToken);
		if (_miningAmount < _self.miningMinGulpAmount) return true;
		_self._convertMiningToUnderlying(G.min(_miningAmount, _self.miningMaxGulpAmount));
		return G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
	}

	function adjustLeverage(Self storage _self) public returns (bool _success)
	{
		uint256 _borrowAmount = G.fetchBorrowAmount(_self.reserveToken);
		if (!_self.leverageEnabled) return _self._decreaseLeverage(_borrowAmount);
		uint256 _lendAmount = G.fetchLendAmount(_self.reserveToken);
		uint256 _idealAmount = _self._calcIdealAmount(_lendAmount);
		uint256 _deviationAmount = _self._calcDeviationAmount(_lendAmount);
		if (_borrowAmount < _idealAmount.sub(_deviationAmount)) return _self._increaseLeverage(_idealAmount.sub(_borrowAmount));
		if (_borrowAmount > _idealAmount.add(_deviationAmount)) return _self._decreaseLeverage(_borrowAmount.sub(_idealAmount));
		return true;
	}

	function _getAvailableUnderlying(Self storage _self) internal view returns (uint256 _availableUnderlying)
	{
		uint256 _lendAmount = G.getLendAmount(_self.reserveToken);
		uint256 _deathAmount = _self._calcDeathAmount(_lendAmount);
		uint256 _limitAmount = _self._calcLimitAmount(_lendAmount);
		uint256 _marginAmount = _deathAmount.sub(_limitAmount);
		return G.getAvailableAmount(_self.reserveToken, _marginAmount);
	}

	function _getAvailableBorrow(Self storage _self) internal view returns (uint256 _availableBorrow)
	{
		uint256 _lendAmount = G.getLendAmount(_self.reserveToken);
		uint256 _deathAmount = _self._calcDeathAmount(_lendAmount);
		uint256 _idealAmount = _self._calcIdealAmount(_lendAmount);
		uint256 _marginAmount = _deathAmount.sub(_idealAmount);
		return G.getAvailableAmount(_self.reserveToken, _marginAmount);
	}

	function _calcIdealAmount(Self storage _self, uint256 _amount) internal view returns (uint256 _idealAmount)
	{
		return _amount.mul(G.getCollateralRatio(_self.reserveToken)).mul(_self.idealCollateralizationRatio).div(1e36);
	}

	function _calcLimitAmount(Self storage _self, uint256 _amount) internal view returns (uint256 _limitAmount)
	{
		return _amount.mul(G.getCollateralRatio(_self.reserveToken)).mul(_self.limitCollateralizationRatio).div(1e36);
	}

	function _calcDeathAmount(Self storage _self, uint256 _amount) internal view returns (uint256 _limitAmount)
	{
		return _amount.mul(G.getCollateralRatio(_self.reserveToken)).div(1e18);
	}

	function _calcDeviationAmount(Self storage _self, uint256 _amount) internal view returns (uint256 _deviationAmount)
	{
		return _amount.mul(G.getCollateralRatio(_self.reserveToken)).mul(_self.collateralizationDeviationRatio).div(1e36);
	}

	function _increaseLeverage(Self storage _self, uint256 _amount) internal returns (bool _success)
	{
		bool _success1 = G.borrow(_self.reserveToken, G.min(_amount, _self._getAvailableBorrow()));
		bool _success2 = G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
		G.repay(_self.reserveToken, G.min(G.getBalance(_self.underlyingToken), G.getBorrowAmount(_self.reserveToken)));
		return _success1 && _success2;
	}

	function _decreaseLeverage(Self storage _self, uint256 _amount) internal returns (bool _success)
	{
		bool _success1 = G.redeem(_self.reserveToken, G.min(_amount, _self._getAvailableUnderlying()));
		bool _success2 = G.repay(_self.reserveToken, G.min(G.getBalance(_self.underlyingToken), G.getBorrowAmount(_self.reserveToken)));
		G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
		return _success1 && _success2;
	}

	function _calcConversionUnderlyingToMiningGivenMining(Self storage _self, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		if (_self.miningToken == _self.underlyingToken) return _outputAmount;
		return G.calcConversionInputFromOutput(_self.underlyingToken, _self.miningToken, _outputAmount);
	}

	function _convertMiningToUnderlying(Self storage _self, uint256 _inputAmount) internal
	{
		if (_self.miningToken == _self.underlyingToken) return;
		G.convertFunds(_self.miningToken, _self.underlyingToken, _inputAmount, 0);
	}
}
