// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

interface LendingPoolAddressesProvider
{
	function getLendingPool() external view returns (address _pool);
	function getLendingPoolCore() external view returns (address payable _lendingPoolCore);
}

interface LendingPool
{
	function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes calldata _params) external;
}

interface FlashLoanReceiver
{
	function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}
