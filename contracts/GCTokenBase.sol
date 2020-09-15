// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { Transfers } from "./Transfers.sol";
import { GFormulae, GTokenBase } from "./GTokenBase.sol";
import { GCToken } from "./GCToken.sol";
import { Comptroller, CToken } from "./interop/Compound.sol";

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

contract CompoundLendingMarketAbstraction is Transfers
{
	constructor (address _ctoken) internal
	{
		Comptroller _comptroller = Comptroller(Addresses.Compound_COMPTROLLER);
		address[] memory _ctokens = new address[](1);
		_ctokens[0] = _ctoken;
		uint256 _result = _comptroller.enterMarkets(_ctokens)[0];
		require(_result == 0, "enterMarkets failed");
	}

	function _getUnderlyingToken(address _ctoken) internal view returns (address _token)
	{
		return CToken(_ctoken).underlying();
	}

	function _getExchangeRate(address _ctoken, address /* _token */) internal returns (uint256 _exchangeRate)
	{
		return CToken(_ctoken).exchangeRateCurrent();
	}

	function _lend(address _ctoken, uint256 /* _camount */, address _token, uint256 _amount) internal
	{
		_approveFunds(_token, _ctoken, _amount);
		uint256 _result = CToken(_ctoken).mint(_amount);
		require(_result == 0, "lend failure");
	}

	function _getRedeemAmount(address /* _ctoken */) internal pure returns (uint256 _redeemAmount)
	{
		return 0; // TODO calculate amount available for redeeming
	}

	function _redeem(address _ctoken, uint256 /* _camount */, address /* _token */, uint256 _amount) internal
	{
		uint256 _result = CToken(_ctoken).redeemUnderlying(_amount);
		require(_result == 0, "redeem failure");
	}

	function _getBorrowAmount(address _ctoken) internal returns (uint256 _borrowAmount)
	{
		return CToken(_ctoken).borrowBalanceCurrent(address(this));
	}

	function _borrow(address _ctoken, address /* _token */, uint256 _amount) internal
	{
		uint256 _result = CToken(_ctoken).borrow(_amount);
		require(_result == 0, "borrow failure");
	}

	function _repay(address _ctoken, address _token, uint256 _amount) internal
	{
		_approveFunds(_token, _ctoken, _amount);
		uint256 _result = CToken(_ctoken).repayBorrow(_amount);
		require(_result == 0, "repay failure");
	}
}

contract GCTokenBase is GTokenBase, GCToken, GCFormulae, CompoundLendingMarketAbstraction
{
	address public immutable underlyingToken;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakeToken, address _reserveToken)
		GTokenBase(_name, _symbol, _decimals, _stakeToken, _reserveToken) CompoundLendingMarketAbstraction(_reserveToken) public
	{
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

	function totalReserveUnderlying() public override returns (uint256 _totalReserveUnderlying)
	{
		return _calcUnderlyingCostFromCost(totalReserve(), _getExchangeRate(reserveToken, underlyingToken));
	}

	function depositUnderlying(uint256 _underlyingCost) external override nonReentrant
	{
		address _from = msg.sender;
		require(_underlyingCost > 0, "deposit underlying cost must be greater than 0");
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _getExchangeRate(reserveToken, underlyingToken));
		(uint256 _netShares, uint256 _feeShares) = calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "deposit shares must be greater than 0");
		_pullFunds(underlyingToken, _from, _underlyingCost);
		_mint(_from, _netShares);
		_mint(sharesToken, _feeShares.div(2));
		_lend(reserveToken, _cost, underlyingToken, _underlyingCost);
		_gulpPoolAssets();
	}

	function withdrawUnderlying(uint256 _grossShares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "withdrawal shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		uint256 _underlyingCost = _calcUnderlyingCostFromCost(_cost, _getExchangeRate(reserveToken, underlyingToken));
		require(_underlyingCost > 0, "withdrawal underlying cost must be greater than 0");
		_redeem(reserveToken, _cost, underlyingToken, _underlyingCost);
		_pushFunds(underlyingToken, _from, _underlyingCost);
		_burn(_from, _grossShares);
		_mint(sharesToken, _feeShares.div(2));
		_gulpPoolAssets();
	}
}
