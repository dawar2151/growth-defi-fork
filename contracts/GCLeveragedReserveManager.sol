// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { G } from "./G.sol";

library GCLeveragedReserveManager
{
	using SafeMath for uint256;

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

	function getLeverageEnabled(Self storage _self) public view returns (bool _leverageEnabled)
	{
		return _self.leverageEnabled;
	}

	function getLeverageAdjustmentAmount(Self storage _self) public view returns (uint256 _leverageAdjustmentAmount)
	{
		return _self.leverageAdjustmentAmount;
	}

	function getIdealCollateralizationRatio(Self storage _self) public view returns (uint256 _idealCollateralizationRatio)
	{
		return _self.idealCollateralizationRatio;
	}

	function getLimitCollateralizationRatio(Self storage _self) public view returns (uint256 _limitCollateralizationRatio)
	{
		return _self.limitCollateralizationRatio;
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
		convertMiningToUnderlying(_self, G.getBalance(_self.miningToken));
		return G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
	}

	function adjustLeverage(Self storage _self) public returns (bool _success)
	{
		uint256 _borrowingAmount = calcConversionUnderlyingToBorrowGivenBorrow(_self, G.fetchBorrowAmount(_self.leverageToken));
		if (!_self.leverageEnabled) return decreaseLeverageLimited(_self, _borrowingAmount);
		uint256 _lendingAmount = G.fetchLendAmount(_self.reserveToken);
		uint256 _limitAmount = calcLimitAmount(_self, _lendingAmount, G.getCollateralRatio(_self.reserveToken));
		if (_borrowingAmount > _limitAmount) return decreaseLeverageLimited(_self, _borrowingAmount.sub(_limitAmount));
		uint256 _idealAmount = calcIdealAmount(_self, _lendingAmount, G.getCollateralRatio(_self.reserveToken));
		if (_borrowingAmount < _idealAmount) return increaseLeverageLimited(_self, _idealAmount.sub(_borrowingAmount));
		return true;
	}

	function calcIdealAmount(Self storage _self, uint256 _amount, uint256 _collateralRatio) public view returns (uint256 _idealAmount)
	{
		return _amount.mul(_collateralRatio).div(1e18).mul(_self.idealCollateralizationRatio).div(1e18);
	}

	function calcLimitAmount(Self storage _self, uint256 _amount, uint256 _collateralRatio) public view returns (uint256 _limitAmount)
	{
		return _amount.mul(_collateralRatio).div(1e18).mul(_self.limitCollateralizationRatio).div(1e18);
	}

	function getAvailableUnderlying(Self storage _self) public view returns (uint256 _availableUnderlying)
	{
		uint256 _lendingAmount = G.getLendAmount(_self.reserveToken);
		uint256 _limitAmount = calcLimitAmount(_self, _lendingAmount, G.getCollateralRatio(_self.reserveToken));
		return G.getAvailableAmount(_self.reserveToken, _limitAmount);
	}

	function getAvailableBorrow(Self storage _self) public view returns (uint256 _availableBorrow)
	{
		return calcConversionUnderlyingToBorrowGivenUnderlying(_self, getAvailableUnderlying(_self));
	}

	function increaseLeverageLimited(Self storage _self, uint256 _amount) public returns (bool _success)
	{
		return increaseLeverage(_self, G.min(_amount, _self.leverageAdjustmentAmount));
	}

	function decreaseLeverageLimited(Self storage _self, uint256 _amount) public returns (bool _success)
	{
		return decreaseLeverage(_self, G.min(_amount, _self.leverageAdjustmentAmount));
	}

	function increaseLeverage(Self storage _self, uint256 _amount) public returns (bool _success)
	{
		_success = G.borrow(_self.leverageToken, G.min(calcConversionUnderlyingToBorrowGivenUnderlying(_self, _amount), getAvailableBorrow(_self)));
		if (!_success) return false;
		convertBorrowToUnderlying(_self, G.getBalance(_self.borrowToken));
		G.repay(_self.leverageToken, G.min(G.getBalance(_self.borrowToken), G.getBorrowAmount(_self.leverageToken)));
		convertBorrowToUnderlying(_self, G.getBalance(_self.borrowToken));
		return G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
	}

	function decreaseLeverage(Self storage _self, uint256 _amount) public returns (bool _success)
	{
		_success = G.redeem(_self.reserveToken, G.min(calcConversionUnderlyingToBorrowGivenBorrow(_self, calcConversionBorrowToUnderlyingGivenUnderlying(_self, _amount)), getAvailableUnderlying(_self)));
		if (!_success) return false;
		convertUnderlyingToBorrow(_self, G.getBalance(_self.underlyingToken));
		_success = G.repay(_self.leverageToken, G.min(G.getBalance(_self.borrowToken), G.getBorrowAmount(_self.leverageToken)));
		convertBorrowToUnderlying(_self, G.getBalance(_self.borrowToken));
		G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
		return _success;
	}

	function calcConversionUnderlyingToBorrowGivenUnderlying(Self storage _self, uint256 _inputAmount) public view /*virtual*/ returns (uint256 _outputAmount)
	{
		return G.calcConversionOutputFromInput(_self.underlyingToken, _self.borrowToken, _inputAmount);
	}

	function calcConversionUnderlyingToBorrowGivenBorrow(Self storage _self, uint256 _outputAmount) public view /*virtual*/ returns (uint256 _inputAmount)
	{
		return G.calcConversionInputFromOutput(_self.underlyingToken, _self.borrowToken, _outputAmount);
	}

	function calcConversionBorrowToUnderlyingGivenUnderlying(Self storage _self, uint256 _outputAmount) public view /*virtual*/ returns (uint256 _inputAmount)
	{
		return G.calcConversionInputFromOutput(_self.borrowToken, _self.underlyingToken, _outputAmount);
	}

	function convertMiningToUnderlying(Self storage _self, uint256 _inputAmount) public /*virtual*/
	{
		G.convertBalance(_self.miningToken, _self.underlyingToken, _inputAmount, 0);
	}

	function convertBorrowToUnderlying(Self storage _self, uint256 _inputAmount) public /*virtual*/
	{
		G.convertBalance(_self.borrowToken, _self.underlyingToken, _inputAmount, 0);
	}

	function convertUnderlyingToBorrow(Self storage _self, uint256 _inputAmount) public /*virtual*/
	{
		G.convertBalance(_self.underlyingToken, _self.borrowToken, _inputAmount, 0);
	}
}
