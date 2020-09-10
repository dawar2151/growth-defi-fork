// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Comptroller
{
/*
	// function isComptroller() external view returns (bool);
	// function mintAllowed(address _cToken, address _minter, uint256 _mintAmount) external returns (uint256);
	// function mintVerify(address _cToken, address _minter, uint256 _mintAmount, uint256 mintTokens) external;
	// function redeemAllowed(address _cToken, address _redeemer, uint256 _redeemTokens) external returns (uint256);
	// function redeemVerify(address _cToken, address _redeemer, uint256 _redeemAmount, uint256 _redeemTokens) external;
	// function borrowAllowed(address _cToken, address _borrower, uint256 _borrowAmount) external returns (uint256);
	// function borrowVerify(address _cToken, address _borrower, uint256 _borrowAmount) external;
	// function repayBorrowAllowed(address _cToken, address _payer, address _borrower, uint256 _repayAmount) external returns (uint256);
	// function repayBorrowVerify(address _cToken, address _payer, address _borrower, uint256 _repayAmount, uint256 _borrowerIndex) external;
	// function liquidateBorrowAllowed(address _cTokenBorrowed, address _cTokenCollateral, address _liquidator, address _borrower, uint256 _repayAmount) external returns (uint256);
	// function liquidateBorrowVerify(address _cTokenBorrowed, address _cTokenCollateral, address _liquidator, address _borrower, uint256 _repayAmount, uint256 _seizeTokens) external;
	// function seizeAllowed(address _cTokenCollateral, address _cTokenBorrowed, address _liquidator, address _borrower, uint256 _seizeTokens) external returns (uint256);
	// function seizeVerify(address _cTokenCollateral, address _cTokenBorrowed, address _liquidator, address _borrower, uint256 _seizeTokens) external;
	// function transferAllowed(address _cToken, address _src, address _dst, uint256 _transferTokens) external returns (uint256);
	// function transferVerify(address _cToken, address _src, address _dst, uint256 _transferTokens) external;
	// function liquidateCalculateSeizeTokens(address _cTokenBorrowed, address _cTokenCollateral, uint256 _repayAmount) external view returns (uint256, uint256);
	// function accountAssets(address, uint256) external view returns (address);
	// function admin() external view returns (address);
	// function borrowGuardianPaused(address) external view returns (bool);
	// function checkMembership(address account, address cToken) external view returns (bool);
	// function comptrollerImplementation() external view returns (address);
	// function maxAssets() external view returns (uint256);
	// function mintGuardianPaused(address) external view returns (bool);
*/
	function oracle() external view returns (address);
/*
	// function pauseGuardian() external view returns (address);
	// function pendingAdmin() external view returns (address);
	// function pendingComptrollerImplementation() external view returns (address);
	// function seizeGuardianPaused() external view returns (bool);
	// function transferGuardianPaused() external view returns (bool);
*/
	function enterMarkets(address[] calldata _cTokens) external returns (uint256[] memory _errorCodes);
/*
	function exitMarket(address _cTokenAddress) external returns (uint256 _errorCode);
	function getAssetsIn(address _account) external view returns (address[] memory _markets);
	function markets(address _cTokenAddress) external view returns (bool _isListed, uint256 _collateralFactorMantissa);
*/
	function getAccountLiquidity(address _account) external view returns (uint256 _error, uint256 _liquidity, uint256 _shortfall);
/*
	function closeFactorMantissa() external view returns (uint256 _closeFactor);
	function liquidationIncentiveMantissa() external view returns (uint256 _liquidationIncentive);
	// function _acceptAdmin() external returns (uint256);
	// function _acceptImplementation() external returns (uint256);
	// function _become(address _unitroller) external;
	// function _become(address _unitroller, address _oracle, uint256 _closeFactorMantissa, uint256 _maxAssets, bool _reinitializing) external;
	// function _borrowGuardianPaused() external view returns (bool);
	// function _mintGuardianPaused() external view returns (bool);
	// function _setBorrowPaused(address _cToken, bool _state) external returns (bool);
	// function _setCloseFactor(uint256 _newCloseFactorMantissa) external returns (uint256);
	// function _setCollateralFactor(address _cToken, uint256 _newCollateralFactorMantissa) external returns (uint256);
	// function _setLiquidationIncentive(uint256 _newLiquidationIncentiveMantissa) external returns (uint256);
	// function _setMaxAssets(uint256 _newMaxAssets) external returns (uint256);
	// function _setMintPaused(address _cToken, bool _state) external returns (bool);
	// function _setPauseGuardian(address _newPauseGuardian) external returns (uint256);
	// function _setPendingAdmin(address _newPendingAdmin) external returns (uint256);
	// function _setPendingImplementation(address _newPendingImplementation) external returns (uint256);
	// function _setPriceOracle(address _newOracle) external returns (uint256);
	// function _setSeizePaused(bool _state) external returns (bool);
	// function _setTransferPaused(bool _state) external returns (bool);
	// function _supportMarket(address _cToken) external returns (uint256);

	event MarketEntered(address _cToken, address _account);
	event MarketExited(address _cToken, address _account);
	// event MarketListed(address _cToken);
	// event NewCloseFactor(uint256 _oldCloseFactorMantissa, uint256 _newCloseFactorMantissa);
	// event NewCollateralFactor(address _cToken, uint256 _oldCollateralFactorMantissa, uint256 _newCollateralFactorMantissa);
	// event NewLiquidationIncentive(uint256 _oldLiquidationIncentiveMantissa, uint256 _newLiquidationIncentiveMantissa);
	// event NewMaxAssets(uint256 _oldMaxAssets, uint256 _newMaxAssets);
	// event NewPriceOracle(address _oldPriceOracle, address _newPriceOracle);
	// event NewPauseGuardian(address _oldPauseGuardian, address _newPauseGuardian);
	// event ActionPaused(string _action, bool _pauseState);
	// event ActionPaused(address _cToken, string _action, bool _pauseState);
*/
}

interface PriceOracle
{
/*
	// function cDaiAddress() external view returns (address);
	// function cEthAddress() external view returns (address);
	// function cSaiAddress() external view returns (address);
	// function cUsdcAddress() external view returns (address);
	// function comptroller() external view returns (address);
	// function isPriceOracle() external view returns (bool);
	// function makerUsdOracleKey() external view returns (address);
	// function v1PriceOracle() external view returns (address);
*/
	function getUnderlyingPrice(address _cToken) external view returns (uint256 _price);
}

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
*/
	function exchangeRateCurrent() external returns (uint256 _exchangeRate);
/*
	function getCash() external view returns (uint256 _cash);
	function totalBorrowsCurrent() external returns (uint256 _totalBorrows);
*/
	function borrowBalanceCurrent(address _account) external returns (uint256 _borrowBalance);
/*
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
*/
	function repayBorrow(uint256 _repayAmount) external returns (uint256 _errorCode); // ERC20
/*
	function repayBorrowBehalf(address _borrower) external payable; // ETH
	function repayBorrowBehalf(address _borrower, uint256 _repayAmount) external returns (uint256 _errorCode); // ERC20
	function liquidateBorrow(address _borrower, address _cTokenCollateral) external payable; // ETH
	function liquidateBorrow(address _borrower, uint256 _repayAmount, address _cTokenCollateral) external returns (uint256 _errorCode); // ERC20
*/
	function redeem(uint256 _redeemTokens) external returns (uint256 _errorCode);
/*
	function redeemUnderlying(uint256 _redeemAmount) external returns (uint256 _errorCode);
*/
	function borrow(uint256 _borrowAmount) external returns (uint256 _errorCode);
/*
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

