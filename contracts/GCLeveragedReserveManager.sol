// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { GExchange } from "./GExchange.sol";
import { G } from "./G.sol";

library GCLeveragedReserveManager
{
	using SafeMath for uint256;
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	uint256 constant DEFAULT_COLLATERALIZATION_RATIO = 96e16; // 96% of 75% = 72%

	struct Self {
		address reserveToken;
		address underlyingToken;

		address miningToken;
		address miningExchange;
		uint256 miningMinGulpAmount;
		uint256 miningMaxGulpAmount;

		uint256 collateralizationRatio;
	}

	function init(Self storage _self, address _reserveToken, address _underlyingToken, address _miningToken) public
	{
		_self.reserveToken = _reserveToken;
		_self.underlyingToken = _underlyingToken;

		_self.miningToken = _miningToken;
		_self.miningExchange = address(0);
		_self.miningMinGulpAmount = 0;
		_self.miningMaxGulpAmount = 0;

		_self.collateralizationRatio = DEFAULT_COLLATERALIZATION_RATIO;

		G.safeEnter(_reserveToken);
	}

	function setMiningExchange(Self storage _self, address _miningExchange) public
	{
		_self.miningExchange = _miningExchange;
	}

	function setMiningGulpRange(Self storage _self, uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) public
	{
		require(_miningMinGulpAmount <= _miningMaxGulpAmount, "invalid range");
		_self.miningMinGulpAmount = _miningMinGulpAmount;
		_self.miningMaxGulpAmount = _miningMaxGulpAmount;
	}

	function setCollateralizationRatio(Self storage _self, uint256 _collateralizationRatio) public
	{
		require(_collateralizationRatio <= 1e18, "invalid rate");
		_self.collateralizationRatio = _collateralizationRatio;
	}

	function adjustReserve(Self storage _self, uint256 _roomAmount) public returns (bool _success)
	{
		bool success1 = _self._gulpMiningAssets();
		bool success2 = _self._adjustLeverage(_roomAmount);
		return success1 && success2;
	}

	function _calcCollateralizationRatio(Self storage _self) internal view returns (uint256 _collateralizationRatio)
	{
		return G.getCollateralRatio(_self.reserveToken).mul(_self.collateralizationRatio).div(1e18);
	}

	function _gulpMiningAssets(Self storage _self) internal returns (bool _success)
	{
		uint256 _miningAmount = G.getBalance(_self.miningToken);
		if (_miningAmount == 0) return true;
		if (_miningAmount < _self.miningMinGulpAmount) return true;
		if (_self.miningExchange == address(0)) return true;
		_self._convertMiningToUnderlying(G.min(_miningAmount, _self.miningMaxGulpAmount));
		return G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
	}

	function _adjustLeverage(Self storage _self, uint256 _roomAmount) internal returns (bool _success)
	{
		uint256 _lendAmount = G.fetchLendAmount(_self.reserveToken);
		uint256 _borrowAmount = G.fetchBorrowAmount(_self.reserveToken);
		uint256 _reserveAmount = _lendAmount.sub(_borrowAmount);
		_roomAmount = G.min(_roomAmount, _reserveAmount);
		uint256 _newReserveAmount = _reserveAmount.sub(_roomAmount);
		uint256 _oldLendAmount = _lendAmount.sub(_roomAmount);
		uint256 _newLendAmount = _newReserveAmount;
		_newLendAmount = _newLendAmount.mul(1e18).div(uint256(1e18).sub(_self._calcCollateralizationRatio()));
		if (_newLendAmount > _oldLendAmount) return _self._dispatchFlashLoan(_newLendAmount.sub(_oldLendAmount), 1);
		if (_newLendAmount < _oldLendAmount) return _self._dispatchFlashLoan(_oldLendAmount.sub(_newLendAmount), 2);
		return true;
	}

	function _continueAdjustLeverage(Self storage _self, uint256 _amount, uint256 _fee, uint256 _which) internal returns (bool _success)
	{
		if (_which == 1) {
			bool _success1 = G.lend(_self.reserveToken, _amount.sub(_fee));
			bool _success2 = G.borrow(_self.reserveToken, _amount);
			return _success1 && _success2;
		}
		if (_which == 2) {
			bool _success1 = G.repay(_self.reserveToken, _amount);
			bool _success2 = G.redeem(_self.reserveToken, _amount.add(_fee));
			return _success1 && _success2;
		}
		assert(false);
	}

	function _dispatchFlashLoan(Self storage _self, uint256 _amount, uint256 _which) internal returns (bool _success)
	{
		return G.requestFlashLoan(_self.underlyingToken, _amount, abi.encode(_which));
	}

	function _receiveFlashLoan(Self storage _self, address _token, uint256 _amount, uint256 _fee, bytes memory _params) external returns (bool _success)
	{
		assert(_token == _self.underlyingToken);
		uint256 _which = abi.decode(_params, (uint256));
		return _self._continueAdjustLeverage(_amount, _fee, _which);
	}

	function _convertMiningToUnderlying(Self storage _self, uint256 _inputAmount) internal
	{
		G.dynamicConvertFunds(_self.miningExchange, _self.miningToken, _self.underlyingToken, _inputAmount, 0);
	}
}
