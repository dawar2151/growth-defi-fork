// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { Addresses } from "./Addresses.sol";
import { Transfers } from "./Transfers.sol";
import { Comptroller, PriceOracle, CToken } from "./interop/Compound.sol";

contract CompoundLendingMarketAbstraction is Addresses, Transfers
{
	using SafeMath for uint256;

	function _getUnderlyingToken(address _ctoken) internal view returns (address _token)
	{
		return CToken(_ctoken).underlying();
	}

	function _getCollateralRatio(address _ctoken) internal view returns (uint256 _collateralFactor)
	{
		address _comptroller = Compound_COMPTROLLER;
		(, _collateralFactor) = Comptroller(_comptroller).markets(_ctoken);
		return _collateralFactor;
	}

	function _getAvailableAmount(address _ctoken) internal view returns (uint256 _amount)
	{
		address _comptroller = Compound_COMPTROLLER;
		(uint256 _result, uint256 _liquidity, uint256 _shortfall) = Comptroller(_comptroller).getAccountLiquidity(address(this));
		if (_result != 0) return 0;
		if (_shortfall > 0) return 0;
		address _priceOracle = Comptroller(_comptroller).oracle();
		uint256 _price = PriceOracle(_priceOracle).getUnderlyingPrice(_ctoken);
		uint256 _accountAmount = _liquidity.mul(1e18).div(_price);
		uint256 _marketAmount = CToken(_ctoken).getCash();
		return _accountAmount < _marketAmount ? _accountAmount : _marketAmount;
	}

	function _getExchangeRate(address _ctoken) internal view returns (uint256 _exchangeRate)
	{
		return CToken(_ctoken).exchangeRateStored();
	}

	function _fetchExchangeRate(address _ctoken) internal returns (uint256 _exchangeRate)
	{
		return CToken(_ctoken).exchangeRateCurrent();
	}

	function _getLendAmount(address _ctoken) internal view returns (uint256 _amount)
	{
		return CToken(_ctoken).balanceOf(address(this)).mul(_getExchangeRate(_ctoken)).div(1e18);
	}

	function _fetchLendAmount(address _ctoken) internal returns (uint256 _amount)
	{
		return CToken(_ctoken).balanceOfUnderlying(address(this));
	}

	function _getBorrowAmount(address _ctoken) internal view returns (uint256 _amount)
	{
		return CToken(_ctoken).borrowBalanceStored(address(this));
	}

	function _fetchBorrowAmount(address _ctoken) internal returns (uint256 _amount)
	{
		return CToken(_ctoken).borrowBalanceCurrent(address(this));
	}

	function _enter(address _ctoken) internal returns (bool _success)
	{
		address _comptroller = Compound_COMPTROLLER;
		address[] memory _ctokens = new address[](1);
		_ctokens[0] = _ctoken;
		return Comptroller(_comptroller).enterMarkets(_ctokens)[0] == 0;
	}

	function _lend(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		address _token = _getUnderlyingToken(_ctoken);
		_approveFunds(_token, _ctoken, _amount);
		return CToken(_ctoken).mint(_amount) == 0;
	}

	function _redeem(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		return CToken(_ctoken).redeemUnderlying(_amount) == 0;
	}

	function _borrow(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		return CToken(_ctoken).borrow(_amount) == 0;
	}

	function _repay(address _ctoken, uint256 _amount) internal returns (bool _success)
	{
		address _token = _getUnderlyingToken(_ctoken);
		_approveFunds(_token, _ctoken, _amount);
		return CToken(_ctoken).repayBorrow(_amount) == 0;
	}

	function _safeEnter(address _ctoken) internal
	{
		require(_enter(_ctoken), "enter failed");
	}

	function _safeLend(address _ctoken, uint256 _amount) internal
	{
		require(_lend(_ctoken, _amount), "lend failure");
	}

	function _safeRedeem(address _ctoken, uint256 _amount) internal
	{
		require(_redeem(_ctoken, _amount), "redeem failure");
	}

	function _safeBorrow(address _ctoken, uint256 _amount) internal
	{
		require(_borrow(_ctoken, _amount), "borrow failure");
	}

	function _safeRepay(address _ctoken, uint256 _amount) internal
	{
		require(_repay(_ctoken, _amount), "repay failure");
	}
}
