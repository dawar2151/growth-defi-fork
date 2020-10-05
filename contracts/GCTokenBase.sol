// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GFormulae } from "./GFormulae.sol";
import { GTokenBase } from "./GTokenBase.sol";
import { GCToken } from "./GCToken.sol";
import { GCFormulae } from "./GCFormulae.sol";
import { G } from "./G.sol";

abstract contract GCTokenBase is GTokenBase, GCToken
{
	address public immutable override miningToken;
	address public immutable override growthToken;
	address public immutable override underlyingToken;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakeToken, address _reserveToken, address _miningToken, address _growthToken)
		GTokenBase(_name, _symbol, _decimals, _stakeToken, _reserveToken) public
	{
		miningToken = _miningToken;
		growthToken = _growthToken;
		address _underlyingToken = G.getUnderlyingToken(_reserveToken);
		underlyingToken = _underlyingToken;
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

	function totalReserveUnderlying() public view virtual override returns (uint256 _totalReserveUnderlying)
	{
		return GCFormulae._calcUnderlyingCostFromCost(totalReserve(), exchangeRate());
	}

	function lendingReserveUnderlying() public view virtual override returns (uint256 _lendingReserveUnderlying)
	{
		return G.getLendAmount(reserveToken);
	}

	function borrowingReserveUnderlying() public view virtual override returns (uint256 _borrowingReserveUnderlying)
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
		G.pullFunds(underlyingToken, _from, _underlyingCost);
		G.safeLend(reserveToken, _underlyingCost);
		require(_prepareDeposit(_cost), "not available at the moment");
		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
	}

	function withdrawUnderlying(uint256 _grossShares) public override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		uint256 _underlyingCost = GCFormulae._calcUnderlyingCostFromCost(_cost, exchangeRate());
		require(_underlyingCost > 0, "underlying cost must be greater than 0");
		require(_prepareWithdrawal(_cost), "not available at the moment");
		_underlyingCost = G.min(_underlyingCost, G.getLendAmount(reserveToken));
		G.safeRedeem(reserveToken, _underlyingCost);
		G.pushFunds(underlyingToken, _from, _underlyingCost);
		_burn(_from, _grossShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
	}
}
