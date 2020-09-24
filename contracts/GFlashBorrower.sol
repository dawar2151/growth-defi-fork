// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { G } from "./G.sol";

import { FlashLoanReceiver } from "./interop/Aave.sol";

abstract contract GFlashBorrower is FlashLoanReceiver
{
	using SafeMath for uint256;

	function executeOperation(address _token, uint256 _amount, uint256 _fee, bytes calldata _params) external override
	{
		require(_processFlashLoan(_token, _amount, _fee, _params), "failure processing flash loan");
		uint256 _grossAmount = _amount.add(_fee);
		G.paybackFlashLoan(_token, _grossAmount);
	}

	function _processFlashLoan(address _token, uint256 _amount, uint256 _fee, bytes calldata _params) internal virtual returns (bool _success);
}
