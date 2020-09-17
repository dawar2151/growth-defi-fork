// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GToken } from "./GToken.sol";
import { GFormulae, GTokenBase } from "./GTokenBase.sol";
import { GCToken } from "./GCToken.sol";
import { GCLeveragedReserveManager } from "./GCLeveragedReserveManager.sol";

contract GCFormulae is GFormulae
{
	function _calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) internal pure returns (uint256 _cost)
	{
		return _underlyingCost.mul(1e18).div(_exchangeRate);
	}

	function _calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) internal pure returns (uint256 _underlyingCost)
	{
		return _cost.mul(_exchangeRate).div(1e18);
	}
}

contract GCTokenBase is GTokenBase, GCToken, GCFormulae, GCLeveragedReserveManager
{
	address public immutable override underlyingToken;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakeToken, address _reserveToken, address _miningToken, address _leverageToken)
		GTokenBase(_name, _symbol, _decimals, _stakeToken, _reserveToken)
		GCLeveragedReserveManager(_reserveToken, _miningToken, _leverageToken) public
	{
		_safeEnter(_reserveToken);
		underlyingToken = _getUnderlyingToken(_reserveToken);
	}

	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) public pure override returns (uint256 _cost)
	{
		return _calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
	}

	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) public pure override returns (uint256 _underlyingCost)
	{
		return _calcUnderlyingCostFromCost(_cost, _exchangeRate);
	}

	function exchangeRate() public view override returns (uint256 _exchangeRate)
	{
		return _getExchangeRate(reserveToken);
	}

	function totalReserve() public view override(GToken, GTokenBase) returns (uint256 _totalReserve)
	{
		return _calcCostFromUnderlyingCost(totalReserveUnderlying(), _getExchangeRate(reserveToken));
	}

	function totalReserveUnderlying() public view override returns (uint256 _totalReserveUnderlying)
	{
		uint256 _lendingReserveUnderlying = lendingReserveUnderlying();
		uint256 _borrowingReserveUnderlying = borrowingReserveUnderlying();
		if (_lendingReserveUnderlying < _borrowingReserveUnderlying) return 0;
		return _lendingReserveUnderlying.sub(_borrowingReserveUnderlying);
	}

	function borrowingReserveUnderlying() public view returns (uint256 _borrowingReserveUnderlying)
	{
		return _calcConversionUnderlyingToBorrowGivenBorrow(_getBorrowAmount(leverageToken));
	}

	function lendingReserveUnderlying() public view returns (uint256 _lendingReserveUnderlying)
	{
		return _getLendAmount(reserveToken);
	}

	function depositUnderlying(uint256 _underlyingCost) external override nonReentrant
	{
		address _from = msg.sender;
		require(_underlyingCost > 0, "deposit underlying cost must be greater than 0");
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _getExchangeRate(reserveToken));
		(uint256 _netShares, uint256 _feeShares) = _calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "deposit shares must be greater than 0");
		_prepareDeposit(_cost);
		_pullFunds(underlyingToken, _from, _underlyingCost);
		_safeLend(reserveToken, _underlyingCost);
		_mint(_from, _netShares);
		_mint(sharesToken, _feeShares.div(2));
		_gulpPoolAssets();
		_adjustReserve();
	}

	function withdrawUnderlying(uint256 _grossShares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "withdrawal shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = _calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		uint256 _underlyingCost = _calcUnderlyingCostFromCost(_cost, _getExchangeRate(reserveToken));
		require(_underlyingCost > 0, "withdrawal underlying cost must be greater than 0");
		_prepareWithdrawal(_cost);
		_safeRedeem(reserveToken, _underlyingCost);
		_pushFunds(underlyingToken, _from, _underlyingCost);
		_burn(_from, _grossShares);
		_mint(sharesToken, _feeShares.div(2));
		_gulpPoolAssets();
		_adjustReserve();
	}

	function setLeverageEnabled(bool _leverageEnabled) public override onlyOwner
	{
		_setLeverageEnabled(_leverageEnabled);
	}

	function setLeverageAdjustmentAmount(uint256 _leverageAdjustmentAmount) public override onlyOwner
	{
		_setLeverageAdjustmentAmount(_leverageAdjustmentAmount);
	}

	function setIdealCollateralizationRatio(uint256 _idealCollateralizationRatio) public override onlyOwner
	{
		_setIdealCollateralizationRatio(_idealCollateralizationRatio);
	}

	function setLimitCollateralizationRatio(uint256 _limitCollateralizationRatio) public override onlyOwner
	{
		_setLimitCollateralizationRatio(_limitCollateralizationRatio);
	}

	function _prepareWithdrawal(uint256 _cost) internal override {
		uint256 _requiredAmount = _calcUnderlyingCostFromCost(_cost, _fetchExchangeRate(reserveToken));
		uint256 _availableAmount = _getAvailableAmount(reserveToken);
		if (_requiredAmount > _availableAmount) {
			require(_decreaseLeverage(_requiredAmount.sub(_availableAmount)), "unliquid market, try again later");
		}
	}

	function _adjustReserve() internal override {
		_gulpMiningAssets();
		_adjustLeverage();
	}
}
