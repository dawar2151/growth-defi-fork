// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { GCToken } from "./GCToken.sol";
import { G } from "./G.sol";

library GCDelegatedReserveManager
{
	using SafeMath for uint256;
	using GCDelegatedReserveManager for GCDelegatedReserveManager.Self;

	uint256 constant DEFAULT_COLLATERALIZATION_RATIO = 80e16; // 80% of 50% = 40%

	struct Self {
		address reserveToken;
		address underlyingToken;

		address miningToken;
		address miningExchange;
		uint256 miningMinGulpAmount;
		uint256 miningMaxGulpAmount;

		address growthToken;
		uint256 collateralizationRatio;
	}

	function init(Self storage _self, address _reserveToken, address _underlyingToken, address _miningToken, address _growthToken) public
	{
		_self.reserveToken = _reserveToken;
		_self.underlyingToken = _underlyingToken;

		_self.miningToken = _miningToken;
		_self.miningExchange = address(0);
		_self.miningMinGulpAmount = 0;
		_self.miningMaxGulpAmount = 0;

		_self.growthToken = _growthToken;
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
		bool success2 = _self._absorbGrowthProfits();
		bool success3 = _self._adjustReserve(_roomAmount);
		return success1 && success2 && success3;
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

	function _absorbGrowthProfits(Self storage _self) internal returns (bool _success)
	{
		GCToken gct = GCToken(_self.growthToken);
		uint256 _borrowAmount = G.fetchBorrowAmount(gct.underlyingToken());
		(uint256 _reserveAmount,) = gct.calcWithdrawalCostFromShares(G.getBalance(address(gct)), gct.totalReserve(), gct.totalSupply(), gct.withdrawalFee());
		uint256 _redeemableAmount = gct.calcUnderlyingCostFromCost(_reserveAmount, gct.exchangeRate());
		if (_redeemableAmount > _borrowAmount) {
			uint256 _profitAmount = _redeemableAmount.sub(_borrowAmount);
			uint256 _cost = gct.calcCostFromUnderlyingCost(_profitAmount, gct.exchangeRate());
			(uint256 _grossShares,) = gct.calcWithdrawalSharesFromCost(_cost, gct.totalReserve(), gct.totalSupply(), gct.withdrawalFee());
			try gct.withdrawUnderlying(_grossShares) {
				return G.repay(gct.reserveToken(), G.getBalance(gct.underlyingToken()));
			} catch (bytes memory /* _data */) {
				return false;
			}
		}
		return true;
	}

	function _adjustReserve(Self storage _self, uint256 _roomAmount) internal returns (bool _success)
	{
/*
		uint256 _lendAmount = G.fetchLendAmount(_self.reserveToken);
		uint256 _borrowAmount = G.fetchBorrowAmount(_self.reserveToken);
		uint256 _reserveAmount = _lendAmount.sub(_borrowAmount);
		_roomAmount = G.min(_roomAmount, _reserveAmount);
		uint256 _newReserveAmount = _reserveAmount.sub(_roomAmount);
		uint256 _oldLendAmount = _lendAmount.sub(_roomAmount);
		uint256 _newLendAmount = _newReserveAmount;
		if (_newLendAmount > _oldLendAmount) {
			bool _success1 = G.lend(_self.reserveToken, _amount.sub(_fee));
			bool _success2 = G.borrow(_self.reserveToken, _amount);
			return _success1 && _success2;
		}
		if (_newLendAmount < _oldLendAmount) {
			bool _success1 = G.repay(_self.reserveToken, _amount);
			bool _success2 = G.redeem(_self.reserveToken, _amount.add(_fee));
			return _success1 && _success2;
		}
		assert(false);
*/
		return true;
	}

	function _convertMiningToUnderlying(Self storage _self, uint256 _inputAmount) internal
	{
		G.dynamicConvertFunds(_self.miningExchange, _self.miningToken, _self.underlyingToken, _inputAmount, 0);
	}
}
