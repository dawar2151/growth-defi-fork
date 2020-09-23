// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GToken } from "./GToken.sol";
import { GFormulae } from "./GFormulae.sol";
import { GTokenBase } from "./GTokenBase.sol";
import { GCToken } from "./GCToken.sol";
import { GCFormulae } from "./GCFormulae.sol";
import { GCLeveragedReserveManager } from "./GCLeveragedReserveManager.sol";
import { G } from "./G.sol";

contract GCTokenBase is GTokenBase, GCToken
{
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	address public immutable override underlyingToken;

	GCLeveragedReserveManager.Self lrm;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakeToken, address _reserveToken, address _miningToken)
		GTokenBase(_name, _symbol, _decimals, _stakeToken, _reserveToken) public
	{
		address _underlyingToken = G.getUnderlyingToken(_reserveToken);
		underlyingToken = _underlyingToken;
		lrm.init(_reserveToken, _underlyingToken, _miningToken);
	}

	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) public pure override returns (uint256 _cost)
	{
		return GCFormulae._calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
	}

	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) public pure override returns (uint256 _underlyingCost)
	{
		return GCFormulae._calcUnderlyingCostFromCost(_cost, _exchangeRate);
	}

	function exchangeRate() public view override returns (uint256 _exchangeRate)
	{
		return G.getExchangeRate(reserveToken);
	}

	function totalReserve() public view override(GToken, GTokenBase) returns (uint256 _totalReserve)
	{
		return GCFormulae._calcCostFromUnderlyingCost(totalReserveUnderlying(), exchangeRate());
	}

	function totalReserveUnderlying() public view override returns (uint256 _totalReserveUnderlying)
	{
		return lendingReserveUnderlying().sub(borrowingReserveUnderlying());
	}

	function lendingReserveUnderlying() public view override returns (uint256 _lendingReserveUnderlying)
	{
		return G.getLendAmount(reserveToken);
	}

	function borrowingReserveUnderlying() public view override returns (uint256 _borrowingReserveUnderlying)
	{
		return G.getBorrowAmount(reserveToken);
	}

	function depositUnderlying(uint256 _underlyingCost) public override nonReentrant
	{
		address _from = msg.sender;
		require(_underlyingCost > 0, "underlying cost must be greater than 0");
		uint256 _cost = GCFormulae._calcCostFromUnderlyingCost(_underlyingCost, exchangeRate());
		(uint256 _netShares, uint256 _feeShares) = GFormulae._calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "shares must be greater than 0");
		require(_prepareDeposit(_cost), "operation not available at the moment");
		G.pullFunds(underlyingToken, _from, _underlyingCost);
		G.safeLend(reserveToken, _underlyingCost);
		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
		_adjustReserve(false);
	}

	function withdrawUnderlying(uint256 _grossShares) public override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		uint256 _underlyingCost = GCFormulae._calcUnderlyingCostFromCost(_cost, exchangeRate());
		require(_underlyingCost > 0, "underlying cost must be greater than 0");
		require(_prepareWithdrawal(_cost), "operation not available at the moment");
//		_underlyingCost = G.min(_underlyingCost, G.getLendAmount(reserveToken));
		G.safeRedeem(reserveToken, _underlyingCost);
		G.pushFunds(underlyingToken, _from, _underlyingCost);
		_burn(_from, _grossShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
		_adjustReserve(false);
	}

	function miningExchange() public view override returns (address _miningExchange)
	{
		return lrm.miningExchange;
	}

	function miningGulpRange() public view override returns (uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount)
	{
		return (lrm.miningMinGulpAmount, lrm.miningMaxGulpAmount);
	}

	function leverageEnabled() public view override returns (bool _leverageEnabled)
	{
		return lrm.leverageEnabled;
	}

	function idealCollateralizationRatio() public view override returns (uint256 _idealCollateralizationRatio)
	{
		return lrm.idealCollateralizationRatio;
	}

	function limitCollateralizationRatio() public view override returns (uint256 _limitCollateralizationRatio)
	{
		return lrm.limitCollateralizationRatio;
	}

	function collateralizationDeviationRatio() public view override returns (uint256 _collateralizationDeviationRatio)
	{
		return lrm.collateralizationDeviationRatio;
	}

	function setMiningExchange(address _miningExchange) public override onlyOwner nonReentrant
	{
		lrm.setMiningExchange(_miningExchange);
	}

	function setMiningGulpRange(uint256 _miningMinGulpAmount, uint256 _miningMaxGulpAmount) public override onlyOwner nonReentrant
	{
		lrm.setMiningGulpRange(_miningMinGulpAmount, _miningMaxGulpAmount);
	}

	function setLeverageEnabled(bool _leverageEnabled) public override onlyOwner nonReentrant
	{
		lrm.setLeverageEnabled(_leverageEnabled);
	}

	function setIdealCollateralizationRatio(uint256 _idealCollateralizationRatio) public override onlyOwner nonReentrant
	{
		lrm.setIdealCollateralizationRatio(_idealCollateralizationRatio);
	}

	function setLimitCollateralizationRatio(uint256 _limitCollateralizationRatio) public override onlyOwner nonReentrant
	{
		lrm.setLimitCollateralizationRatio(_limitCollateralizationRatio);
	}

	function setCollateralizationDeviationRatio(uint256 _collateralizationDeviationRatio) public override onlyOwner nonReentrant
	{
		return lrm.setCollateralizationDeviationRatio(_collateralizationDeviationRatio);
	}

	function _prepareWithdrawal(uint256 _cost) internal override returns (bool _success)
	{
		return lrm.ensureLiquidity(GCFormulae._calcUnderlyingCostFromCost(_cost, G.fetchExchangeRate(reserveToken)));
	}

	function _adjustReserve(bool _explicit) internal override returns (bool _success)
	{
		_explicit; // silences warnings
		uint256 _oldLend = G.fetchLendAmount(reserveToken);
		uint256 _oldBorrow = G.fetchBorrowAmount(reserveToken);
		bool _success1 = lrm.gulpMiningAssets();
		bool _success2 = lrm.adjustLeverage();
		uint256 _newLend = G.fetchLendAmount(reserveToken);
		uint256 _newBorrow = G.fetchBorrowAmount(reserveToken);
		if (_newLend != _oldLend || _newBorrow != _oldBorrow) {
			emit ReserveChange(_newLend, _newBorrow);
		}
		return _success1 && _success2;
	}

	event ReserveChange(uint256 _lendingReserveUnderlying, uint256 _borrowingReserveUnderlying);
}
