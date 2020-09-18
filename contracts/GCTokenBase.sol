// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GToken } from "./GToken.sol";
import { GTokenBase } from "./GTokenBase.sol";
import { GCToken } from "./GCToken.sol";
import { GCLeveragedReserveManager } from "./GCLeveragedReserveManager.sol";
import { G } from "./G.sol";

contract GCTokenBase is GTokenBase, GCToken, GCLeveragedReserveManager
{
	address public immutable override leverageToken;
	address public immutable override underlyingToken;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakeToken, address _miningToken, address _reserveToken, address _leverageToken, uint256 _leverageAdjustmentAmount)
		GTokenBase(_name, _symbol, _decimals, _stakeToken, _reserveToken)
		GCLeveragedReserveManager(_miningToken, _reserveToken, _leverageToken, _leverageAdjustmentAmount) public
	{
		leverageToken = _leverageToken;
		underlyingToken = G.getUnderlyingToken(_reserveToken);
	}

	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) public pure override returns (uint256 _cost)
	{
		return G.calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
	}

	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) public pure override returns (uint256 _underlyingCost)
	{
		return G.calcUnderlyingCostFromCost(_cost, _exchangeRate);
	}

	function exchangeRate() public view override returns (uint256 _exchangeRate)
	{
		return G.getExchangeRate(reserveToken);
	}

	function totalReserve() public view override(GToken, GTokenBase) returns (uint256 _totalReserve)
	{
		return G.calcCostFromUnderlyingCost(totalReserveUnderlying(), G.getExchangeRate(reserveToken));
	}

	function totalReserveUnderlying() public view override returns (uint256 _totalReserveUnderlying)
	{
		uint256 _lendingReserveUnderlying = lendingReserveUnderlying();
		uint256 _borrowingReserveUnderlying = borrowingReserveUnderlying();
		if (_lendingReserveUnderlying <= _borrowingReserveUnderlying) return 0;
		return _lendingReserveUnderlying.sub(_borrowingReserveUnderlying);
	}

	function lendingReserveUnderlying() public view override returns (uint256 _lendingReserveUnderlying)
	{
		return G.getLendAmount(reserveToken);
	}

	function borrowingReserveUnderlying() public view override returns (uint256 _borrowingReserveUnderlying)
	{
		return _calcConversionUnderlyingToBorrowGivenBorrow(G.getBorrowAmount(leverageToken));
	}

	function depositUnderlying(uint256 _underlyingCost) external override nonReentrant
	{
		address _from = msg.sender;
		require(_underlyingCost > 0, "deposit underlying cost must be greater than 0");
		uint256 _cost = G.calcCostFromUnderlyingCost(_underlyingCost, G.getExchangeRate(reserveToken));
		(uint256 _netShares, uint256 _feeShares) = G.calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "deposit shares must be greater than 0");
		_prepareDeposit(_cost);
		G.pullFunds(underlyingToken, _from, _underlyingCost);
		G.safeLend(reserveToken, _underlyingCost);
		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));
		_gulpPoolAssets();
		_adjustReserve();
	}

	function withdrawUnderlying(uint256 _grossShares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "withdrawal shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = G.calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		uint256 _underlyingCost = G.calcUnderlyingCostFromCost(_cost, G.getExchangeRate(reserveToken));
		require(_underlyingCost > 0, "withdrawal underlying cost must be greater than 0");
		_prepareWithdrawal(_cost);
		G.safeRedeem(reserveToken, _underlyingCost);
		G.pushFunds(underlyingToken, _from, _underlyingCost);
		_burn(_from, _grossShares);
		_mint(address(this), _feeShares.div(2));
		_gulpPoolAssets();
		_adjustReserve();
	}

	function leverageEnabled() public view override returns (bool _leverageEnabled)
	{
		return _getLeverageEnabled();
	}

	function leverageAdjustmentAmount() public view override returns (uint256 _leverageAdjustmentAmount)
	{
		return _getLeverageAdjustmentAmount();
	}

	function idealCollateralizationRatio() external view override returns (uint256 _idealCollateralizationRatio)
	{
		return _getIdealCollateralizationRatio();
	}

	function limitCollateralizationRatio() external view override returns (uint256 _limitCollateralizationRatio)
	{
		return _getLimitCollateralizationRatio();
	}

	function setLeverageEnabled(bool _leverageEnabled) public override onlyOwner nonReentrant
	{
		_setLeverageEnabled(_leverageEnabled);
	}

	function setLeverageAdjustmentAmount(uint256 _leverageAdjustmentAmount) public override onlyOwner nonReentrant
	{
		_setLeverageAdjustmentAmount(_leverageAdjustmentAmount);
	}

	function setIdealCollateralizationRatio(uint256 _idealCollateralizationRatio) public override onlyOwner nonReentrant
	{
		_setIdealCollateralizationRatio(_idealCollateralizationRatio);
	}

	function setLimitCollateralizationRatio(uint256 _limitCollateralizationRatio) public override onlyOwner nonReentrant
	{
		_setLimitCollateralizationRatio(_limitCollateralizationRatio);
	}

	function _prepareWithdrawal(uint256 _cost) internal override {
		uint256 _requiredAmount = G.calcUnderlyingCostFromCost(_cost, G.fetchExchangeRate(reserveToken));
		uint256 _availableAmount = _getAvailableUnderlying();
		if (_requiredAmount <= _availableAmount) return;
		require(_decreaseLeverage(_requiredAmount.sub(_availableAmount)), "unliquid market, try again later");
	}

	function _adjustReserve() internal override {
		require(_gulpMiningAssets(), "failure gulping mining assets");
		require(_adjustLeverage(), "failure adjusting leverage");
	}
}
