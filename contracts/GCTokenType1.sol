// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { GCFormulae } from "./GCFormulae.sol";
import { GCTokenBase } from "./GCTokenBase.sol";
import { GCLeveragedReserveManager } from "./GCLeveragedReserveManager.sol";
import { GFlashBorrower } from "./GFlashBorrower.sol";
import { G } from "./G.sol";

contract GCTokenType1 is GCTokenBase, GFlashBorrower
{
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	GCLeveragedReserveManager.Self lrm;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakeToken, address _reserveToken, address _miningToken)
		GCTokenBase(_name, _symbol, _decimals, _stakeToken, _reserveToken, _miningToken, address(0)) public
	{
		address _underlyingToken = G.getUnderlyingToken(_reserveToken);
		lrm.init(_reserveToken, _underlyingToken, _miningToken);
	}

	function totalReserve() public view override returns (uint256 _totalReserve)
	{
		return GCFormulae._calcCostFromUnderlyingCost(totalReserveUnderlying(), exchangeRate());
	}

	function totalReserveUnderlying() public view override returns (uint256 _totalReserveUnderlying)
	{
		return lendingReserveUnderlying().sub(borrowingReserveUnderlying());
	}

	function exchange() public view override returns (address _exchange)
	{
		return lrm.exchange;
	}

	function miningGulpRange() public view override returns (uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount)
	{
		return (lrm.miningMinGulpAmount, lrm.miningMaxGulpAmount);
	}

	function growthGulpRange() public view override returns (uint256 _growthMinGulpAmount, uint256 _growthMaxGulpAmount)
	{
		return (0, 0);
	}

	function collateralizationRatio() public view override returns (uint256 _collateralizationRatio, uint256 _collateralizationMargin)
	{
		return (lrm.collateralizationRatio, lrm.collateralizationMargin);
	}

	function setExchange(address _exchange) public override onlyOwner nonReentrant
	{
		lrm.setExchange(_exchange);
	}

	function setMiningGulpRange(uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) public override onlyOwner nonReentrant
	{
		lrm.setMiningGulpRange(_miningMinGulpAmount, _miningMaxGulpAmount);
	}

	function setGrowthGulpRange(uint256 /* _growthMinGulpAmount */, uint256 /* _growthMaxGulpAmount */) public override /*onlyOwner nonReentrant*/
	{
	}

	function setCollateralizationRatio(uint256 _collateralizationRatio, uint256 _collateralizationMargin) public override onlyOwner nonReentrant
	{
		lrm.setCollateralizationRatio(_collateralizationRatio, _collateralizationMargin);
	}

	function _prepareWithdrawal(uint256 _cost) internal override mayFlashBorrow returns (bool _success)
	{
		return lrm.adjustReserve(GCFormulae._calcUnderlyingCostFromCost(_cost, G.fetchExchangeRate(reserveToken)));
	}

	function _prepareDeposit(uint256 /* _cost */) internal override mayFlashBorrow returns (bool _success)
	{
		return lrm.adjustReserve(0);
	}

	function _processFlashLoan(address _token, uint256 _amount, uint256 _fee, bytes memory _params) internal override returns (bool _success)
	{
		return lrm._receiveFlashLoan(_token, _amount, _fee, _params);
	}
}
