// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { GExchange } from "./GExchange.sol";
import { G } from "./G.sol";

library GCLeveragedReserveManager
{
	using SafeMath for uint256;
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	uint256 constant RATIO_MARGIN = 4e16; // 4%
	uint256 constant IDEAL_COLLATERALIZATION_RATIO = 96e16; // 96% of 75% = 72%

	struct Self {
		address reserveToken;
		address underlyingToken;

		address miningToken;
		address miningExchange;
		uint256 miningMinGulpAmount;
		uint256 miningMaxGulpAmount;

		bool leverageEnabled;
		uint256 idealCollateralizationRatio;
	}

	function init(Self storage _self, address _reserveToken, address _underlyingToken, address _miningToken) public
	{
		_self.reserveToken = _reserveToken;
		_self.underlyingToken = _underlyingToken;

		_self.miningToken = _miningToken;
		_self.miningExchange = address(0);
		_self.miningMinGulpAmount = 0;
		_self.miningMaxGulpAmount = 0;

		_self.leverageEnabled = false;
		_self.idealCollateralizationRatio = G.getCollateralRatio(_reserveToken).mul(IDEAL_COLLATERALIZATION_RATIO).div(1e18);

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

	function setLeverageEnabled(Self storage _self, bool _leverageEnabled) public
	{
		_self.leverageEnabled = _leverageEnabled;
	}

	function gulpMiningAssets(Self storage _self) public returns (bool _success)
	{
		uint256 _miningAmount = G.getBalance(_self.miningToken);
		if (_miningAmount == 0) return true;
		if (_miningAmount < _self.miningMinGulpAmount) return true;
		if (_self.miningExchange == address(0)) return false;
		_self._convertMiningToUnderlying(G.min(_miningAmount, _self.miningMaxGulpAmount));
		return G.lend(_self.reserveToken, G.getBalance(_self.underlyingToken));
	}

	function ensureLiquidity(Self storage _self, uint256 _requiredAmount) public returns (bool _success)
	{
		return _self._adjustLeverageWithRoom(_requiredAmount);
	}

	function adjustLeverage(Self storage _self) public returns (bool _success)
	{
		return _self._adjustLeverageWithRoom(0);
	}

	function _adjustLeverageWithRoom(Self storage _self, uint256 _roomAmount) internal returns (bool _success)
	{
		uint256 _lendAmount = G.fetchLendAmount(_self.reserveToken);
		uint256 _borrowAmount = G.fetchBorrowAmount(_self.reserveToken);
		uint256 _reserveAmount = _lendAmount.sub(_borrowAmount);
		_roomAmount = G.min(_roomAmount, _reserveAmount);
		uint256 _newReserveAmount = _reserveAmount.sub(_roomAmount);
		uint256 _oldLendAmount = _lendAmount.sub(_roomAmount);
		uint256 _newLendAmount = _newReserveAmount;
		if (_self.leverageEnabled) _newLendAmount = _newLendAmount.mul(1e18).div(uint256(1e18).sub(_self.idealCollateralizationRatio));
		if (_newLendAmount > _oldLendAmount) return _self._dispatchFlashLoan(_newLendAmount.sub(_oldLendAmount), 1);
		if (_newLendAmount < _oldLendAmount) return _self._dispatchFlashLoan(_oldLendAmount.sub(_newLendAmount), 2);
		return true;
	}

	function _continueAdjustLeverageWithRoom(Self storage _self, uint256 _amount, uint256 _fee, uint256 _which) internal returns (bool _success)
	{
		uint256 _lendFee = _fee.mul(1e18).div(uint256(1e18).add(_self.idealCollateralizationRatio));
		uint256 _borrowFee = _fee.sub(_lendFee);
		if (_which == 1) {
			bool _success1 = G.lend(_self.reserveToken, _amount.sub(_lendFee));
			bool _success2 = G.borrow(_self.reserveToken, _amount.add(_borrowFee));
			return _success1 && _success2;
		}
		if (_which == 2) {
			bool _success1 = G.repay(_self.reserveToken, _amount.sub(_borrowFee));
			bool _success2 = G.redeem(_self.reserveToken, _amount.add(_lendFee));
			return _success1 && _success2;
		}
		require(false, "invalid operation");
	}

	function _dispatchFlashLoan(Self storage _self, uint256 _amount, uint256 _which) internal returns (bool _success)
	{
		return G.requestFlashLoan(_self.underlyingToken, _amount, abi.encode(_which));
	}

	function _receiveFlashLoan(Self storage _self, address _token, uint256 _amount, uint256 _fee, bytes calldata _params) public returns (bool _success)
	{
		require(_token == _self.underlyingToken, "invalid token");
		(uint256 _which) = abi.decode(_params, (uint256));
		return _self._continueAdjustLeverageWithRoom(_amount, _fee, _which);
	}

	function _convertMiningToUnderlying(Self storage _self, uint256 _inputAmount) internal
	{
		string memory _signature = "convertFunds(address,address,uint256,uint256)";
		bytes memory _params = abi.encodeWithSignature(_signature, _self.miningToken, _self.underlyingToken, _inputAmount, 0);
		(bool _success, bytes memory _result) = _self.miningExchange.delegatecall(_params);
		_success; _result; // silences warnings
	}
}
