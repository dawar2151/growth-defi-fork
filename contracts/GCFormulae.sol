// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { GFormulae } from "./GFormulae.sol";

library GCFormulae
{
	using SafeMath for uint256;

	function _calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) internal pure returns (uint256 _cost)
	{
		return _underlyingCost.mul(1e18).div(_exchangeRate);
	}

	function _calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) internal pure returns (uint256 _underlyingCost)
	{
		return _cost.mul(_exchangeRate).div(1e18);
	}

	function _calcDepositSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) internal pure returns (uint256 _netShares, uint256 _feeShares)
	{
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
		return GFormulae._calcDepositSharesFromCost(_cost, _totalReserve, _totalSupply, _depositFee);
	}

	function _calcDepositUnderlyingCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee, uint256 _exchangeRate) internal pure returns (uint256 _underlyingCost, uint256 _feeShares)
	{
		uint256 _cost;
		(_cost, _feeShares) = GFormulae._calcDepositCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee);
		return (_calcUnderlyingCostFromCost(_cost, _exchangeRate), _feeShares);
	}

	function _calcWithdrawalSharesFromUnderlyingCost(uint256 _underlyingCost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) internal pure returns (uint256 _grossShares, uint256 _feeShares)
	{
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
		return GFormulae._calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
	}

	function _calcWithdrawalUnderlyingCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee, uint256 _exchangeRate) internal pure returns (uint256 _underlyingCost, uint256 _feeShares)
	{
		uint256 _cost;
		(_cost, _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee);
		return (_calcUnderlyingCostFromCost(_cost, _exchangeRate), _feeShares);
	}
}
