// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface CToken is IERC20
{
/*
	// function pendingAdmin() external view returns (address);
	// function totalBorrows() external view returns (uint256);
	// function comptroller() external view returns (address);
	// function accrualBlockNumber() external view returns (uint256);
	// function borrowIndex() external view returns (uint256);
	// function interestRateModel() external view returns (address);
	// function admin() external view returns (address);
	// function isCToken() external view returns (bool);
	// function underlying() external view returns (address);
	// function initialExchangeRateMantissa() external view returns (uint256);
	// function getAccountSnapshot(address _account) external view returns (uint256, uint256, uint256, uint256);
	// function exchangeRateStored() external view returns (uint256 _exchangeRateStored);
	// function borrowBalanceStored(address _account) external view returns (uint256);
	// function accrueInterest() external returns (uint256 _accrueInterest);
	// function seize(address _liquidator, address _borrower, uint256 _seizeTokens) external returns (uint256);
	function exchangeRateCurrent() external returns (uint256 _exchangeRate);
	function getCash() external view returns (uint256 _cash);
	function totalBorrowsCurrent() external returns (uint256 _totalBorrows);
	function borrowBalanceCurrent(address _account) external returns (uint256 _borrowBalance);
	function borrowRatePerBlock() external view returns (uint256 _borrowRate);
	function balanceOfUnderlying(address _owner) external returns (uint256 _underlyingBalance);
	function supplyRatePerBlock() external view returns (uint256 _supplyRate);
	function totalReserves() external view returns (uint256 _totalReserves);
	function reserveFactorMantissa() external view returns (uint256 _reserveFactor);
	function mint() external payable; // ETH
*/
	function mint(uint256 _mintAmount) external returns (uint256 _errorCode); // ERC20
/*
	function repayBorrow() external payable; // ETH
	function repayBorrow(uint256 _repayAmount) external returns (uint256 _errorCode); // ERC20
	function repayBorrowBehalf(address _borrower) external payable; // ETH
	function repayBorrowBehalf(address _borrower, uint256 _repayAmount) external returns (uint256 _errorCode); // ERC20
	function liquidateBorrow(address _borrower, address _cTokenCollateral) external payable; // ETH
	function liquidateBorrow(address _borrower, uint256 _repayAmount, address _cTokenCollateral) external returns (uint256 _errorCode); // ERC20
*/
	function redeem(uint256 _redeemTokens) external returns (uint256 _errorCode);
/*
	function redeemUnderlying(uint256 _redeemAmount) external returns (uint256 _errorCode);
	function borrow(uint256 _borrowAmount) external returns (uint256 _errorCode);
	// function _setComptroller(address _newComptroller) external returns (uint256);
	// function _reduceReserves(uint256 _reduceAmount) external returns (uint256);
	// function _setPendingAdmin(address _newPendingAdmin) external returns (uint256);
	// function _acceptAdmin() external returns (uint256);
	// function _setInterestRateModel(address _newInterestRateModel) external returns (uint256);
	// function _setReserveFactor(uint256 _newReserveFactorMantissa) external returns (uint256);
	// function _addReserves(uint256 _addAmount) external returns (uint256);

	event Mint(address _minter, uint256 _mintAmount, uint256 _mintTokens);
	event Redeem(address _redeemer, uint256 _redeemAmount, uint256 _redeemTokens);
	event Borrow(address _borrower, uint256 _borrowAmount, uint256 _accountBorrows, uint256 _totalBorrows);
	event RepayBorrow(address _payer, address _borrower, uint256 _repayAmount, uint256 _accountBorrows, uint256 _totalBorrows);
	event LiquidateBorrow(address _liquidator, address _borrower, uint256 _repayAmount, address _cTokenCollateral, uint256 _seizeTokens);
	// event AccrueInterest(uint256 _cashPrior, uint256 _interestAccumulated, uint256 _borrowIndex, uint256 _totalBorrows);
	// event NewPendingAdmin(address _oldPendingAdmin, address _newPendingAdmin);
	// event NewAdmin(address _oldAdmin, address _newAdmin);
	// event NewComptroller(address _oldComptroller, address _newComptroller);
	// event NewMarketInterestRateModel(address _oldInterestRateModel, address _newInterestRateModel);
	// event NewReserveFactor(uint256 _oldReserveFactorMantissa, uint256 _newReserveFactorMantissa);
	// event ReservesAdded(address _benefactor, uint256 _addAmount, uint256 _newTotalReserves);
	// event ReservesReduced(address _admin, uint256 _reduceAmount, uint256 _newTotalReserves);
	// event Failure(uint256 _error, uint256 _info, uint256 _detail);
*/
}

