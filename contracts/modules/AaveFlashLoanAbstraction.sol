// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { Transfers } from "./Transfers.sol";

import { LendingPoolAddressesProvider, LendingPool } from "../interop/Aave.sol";

import { $ } from "../network/$.sol";

library AaveFlashLoanAbstraction
{
	using SafeMath for uint256;

	uint256 constant FLASH_LOAN_FEE_RATIO = 9e14; // 0.09%

	function _estimateFlashLoanFee(uint256 _netAmount) internal pure returns (uint256 _feeAmount)
	{
		return _netAmount.mul(FLASH_LOAN_FEE_RATIO).div(1e18);
	}

	function _requestFlashLoan(address _token, uint256 _netAmount, bytes memory _context) internal returns (bool _success) {
		address _provider = $.AAVE_LENDING_POOL_ADDRESSES_PROVIDER;
		address _pool = LendingPoolAddressesProvider(_provider).getLendingPool();
		try LendingPool(_pool).flashLoan(address(this), _token, _netAmount, _context) {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	function _paybackFlashLoan(address _token, uint256 _grossAmount) internal {
		address _provider = $.AAVE_LENDING_POOL_ADDRESSES_PROVIDER;
		address _poolCore = LendingPoolAddressesProvider(_provider).getLendingPoolCore();
		Transfers._pushFunds(_token, _poolCore, _grossAmount);
	}
}
