// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

library AaveLendingMarketAbstraction
{
	function _getUnderlyingToken(address _atoken) internal view returns (address _token)
	{
//		function underlyingAssetAddress() external view returns (address _underlyingAssetAddress);
	}

	function _getCollateralRatio(address _atoken) internal view returns (uint256 _collateralFactor)
	{
	}

	function _getMarketAmount(address _atoken) internal view returns (uint256 _marketAmount)
	{
//		function getReserveAvailableLiquidity(address _reserve) external view returns (uint256);
//		function getReserveData(address _reserve) external view returns (uint256 _totalLiquidity, uint256 _availableLiquidity, uint256 _totalBorrowsStable, uint256 _totalBorrowsVariable, uint256 _liquidityRate, uint256 _variableBorrowRate, uint256 _stableBorrowRate, uint256 _averageStableBorrowRate, uint256 _utilizationRate, uint256 _liquidityIndex, uint256 _variableBorrowIndex, address _aTokenAddress, uint40 _lastUpdateTimestamp);
	}

	function _getLiquidityAmount(address _atoken) internal view returns (uint256 _liquidityAmount)
	{
	}

	function _getAvailableAmount(address _atoken, uint256 _marginAmount) internal view returns (uint256 _availableAmount)
	{
	}

	function _getExchangeRate(address _atoken) internal view returns (uint256 _exchangeRate)
	{
//		return 1
	}

	function _fetchExchangeRate(address _atoken) internal returns (uint256 _exchangeRate)
	{
//		return 1
	}

	function _getLendAmount(address _atoken) internal view returns (uint256 _amount)
	{
//		function getUserUnderlyingAssetBalance(address _reserve, address _user) external view returns (uint256);
//		function principalBalanceOf(address _user) external view returns (uint256 _balance);
	}

	function _fetchLendAmount(address _atoken) internal returns (uint256 _amount)
	{
	}

	function _getBorrowAmount(address _atoken) internal view returns (uint256 _amount)
	{
	}

	function _fetchBorrowAmount(address _atoken) internal returns (uint256 _amount)
	{
	}

	function _enter(address _atoken) internal returns (bool _success)
	{
	}

	function _lend(address _atoken, uint256 _amount) internal returns (bool _success)
	{
	}

	function _redeem(address _atoken, uint256 _amount) internal returns (bool _success)
	{
	}

	function _borrow(address _atoken, uint256 _amount) internal returns (bool _success)
	{
	}

	function _repay(address _atoken, uint256 _amount) internal returns (bool _success)
	{
	}

	function _safeEnter(address _atoken) internal
	{
	}

	function _safeLend(address _atoken, uint256 _amount) internal
	{
//		function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external payable;
	}

	function _safeRedeem(address _atoken, uint256 _amount) internal
	{
//		function redeemUnderlying(address _reserve, address payable _user, uint256 _amount, uint256 _aTokenBalanceAfterRedeem) external;
	}

	function _safeBorrow(address _atoken, uint256 _amount) internal
	{
//		function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external;
	}

	function _safeRepay(address _atoken, uint256 _amount) internal
	{
//		function repay(address _reserve, uint256 _amount, address payable _onBehalfOf) external payable;
	}
}
