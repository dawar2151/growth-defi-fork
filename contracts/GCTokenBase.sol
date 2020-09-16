// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "./Addresses.sol";
import { Transfers } from "./Transfers.sol";
import { GFormulae, GTokenBase } from "./GTokenBase.sol";
import { GCToken } from "./GCToken.sol";
import { Comptroller, PriceOracle, CToken } from "./interop/Compound.sol";

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
		address _comptroller = Addresses.Compound_COMPTROLLER;
		address[] memory _ctokens = new address[](1);
		_ctokens[0] = _ctoken;
		uint256 _result = Comptroller(_comptroller).enterMarkets(_ctokens)[0];
		require(_result == 0, "enterMarkets failed");
	}

	function _getUnderlyingToken(address _ctoken) internal view returns (address _token)
	{
		return CToken(_ctoken).underlying();
	}

	function _getExchangeRate(address _ctoken) internal returns (uint256 _exchangeRate)
	{
		return CToken(_ctoken).exchangeRateCurrent();
	}

	function _getAvailableAmount(address _ctoken) internal view returns (uint256 _amount)
	{
		address _comptroller = Addresses.Compound_COMPTROLLER;
		(uint256 _result, uint256 _liquidity, uint256 _shortfall) = Comptroller(_comptroller).getAccountLiquidity(address(this));
		if (_result != 0) return 0;
		if (_shortfall > 0) return 0;
		address _priceOracle = Comptroller(_comptroller).oracle();
		uint256 _price = PriceOracle(_priceOracle).getUnderlyingPrice(_ctoken);
		uint256 _accountAmount = _liquidity / _price;
		uint256 _marketAmount = CToken(_ctoken).getCash();
		return _accountAmount < _marketAmount ? _accountAmount : _marketAmount;
	}

	function _getBorrowAmount(address _ctoken) internal returns (uint256 _amount)
	{
		return CToken(_ctoken).borrowBalanceCurrent(address(this));
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

	function totalReserveUnderlying() public virtual override returns (uint256 _totalReserveUnderlying)
	{
		return _calcUnderlyingCostFromCost(totalReserve(), _getExchangeRate(reserveToken));
	}

	function depositUnderlying(uint256 _underlyingCost) external override nonReentrant
	{
		address _from = msg.sender;
		require(_underlyingCost > 0, "deposit underlying cost must be greater than 0");
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _getExchangeRate(reserveToken));
		(uint256 _netShares, uint256 _feeShares) = calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "deposit shares must be greater than 0");
		_beforeDeposit(_from, _cost, _netShares, _feeShares);
		_pullFunds(underlyingToken, _from, _underlyingCost);
		_safeLend(reserveToken, _underlyingCost);
		_mint(_from, _netShares);
		_mint(sharesToken, _feeShares.div(2));
		_gulpPoolAssets();
		_afterDeposit(_from, _cost, _netShares, _feeShares);
	}

	function withdrawUnderlying(uint256 _grossShares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "withdrawal shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		uint256 _underlyingCost = _calcUnderlyingCostFromCost(_cost, _getExchangeRate(reserveToken));
		require(_underlyingCost > 0, "withdrawal underlying cost must be greater than 0");
		_beforeWithdrawal(_from, _grossShares, _feeShares, _cost);
		_safeRedeem(reserveToken, _underlyingCost);
		_pushFunds(underlyingToken, _from, _underlyingCost);
		_burn(_from, _grossShares);
		_mint(sharesToken, _feeShares.div(2));
		_gulpPoolAssets();
		_afterWithdrawal(_from, _grossShares, _feeShares, _cost);
	}
}
