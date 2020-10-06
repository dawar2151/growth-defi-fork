// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { G } from "./G.sol";

import { FlashLoanReceiver } from "./interop/Aave.sol";
import { ICallee, Account } from "./interop/Dydx.sol";

import { FlashLoans } from "./modules/FlashLoans.sol";

import { $ } from "./network/$.sol";

abstract contract GFlashBorrower is FlashLoanReceiver, ICallee
{
	using SafeMath for uint256;

	uint256 private allowOperationLevel = 0;

	modifier mayFlashBorrow()
	{
		allowOperationLevel++;
		_;
		allowOperationLevel--;
	}

	function executeOperation(address _token, uint256 _amount, uint256 _fee, bytes calldata _params) external override
	{
		assert(allowOperationLevel > 0);
		address _from = msg.sender;
		address _pool = $.Aave_AAVE_LENDING_POOL;
		assert(_from == _pool);
		require(_processFlashLoan(_token, _amount, _fee, _params)/*, "failure processing flash loan"*/);
		G.paybackFlashLoan(FlashLoans.Provider.Aave, _token, _amount.add(_fee));
	}

	function callFunction(address _sender, Account.Info memory _account, bytes memory _data) external override
	{
		assert(allowOperationLevel > 0);
		address _from = msg.sender;
		address _solo = $.Dydx_SOLO_MARGIN;
		assert(_from == _solo);
		assert(_sender == address(this));
		assert(_account.owner == address(this));
		(address _token, uint256 _amount, uint256 _fee, bytes memory _params) = abi.decode(_data, (address,uint256,uint256,bytes));
		require(_processFlashLoan(_token, _amount, _fee, _params)/*, "failure processing flash loan"*/);
		G.paybackFlashLoan(FlashLoans.Provider.Dydx, _token, _amount.add(_fee));
	}

	function _processFlashLoan(address _token, uint256 _amount, uint256 _fee, bytes memory _params) internal virtual returns (bool _success);
}
