// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { AaveFlashLoanAbstraction } from "./AaveFlashLoanAbstraction.sol";
import { DydxFlashLoanAbstraction } from "./DydxFlashLoanAbstraction.sol";

import { $ } from "../network/$.sol";

library FlashLoans
{
	function _estimateFlashLoanFee(address _token, uint256 _netAmount) internal pure returns (uint256 _feeAmount)
	{
		if ($.NETWORK == $.Network.Mainnet || $.NETWORK == $.Network.Kovan) {
			if (_token == $.DAI || _token == $.USDC) {
				return DydxFlashLoanAbstraction._estimateFlashLoanFee(_token, _netAmount);
			}
		}
		return AaveFlashLoanAbstraction._estimateFlashLoanFee(_token, _netAmount);
	}

	function _requestFlashLoan(address _token, uint256 _netAmount, bytes memory _context) internal returns (bool _success)
	{
		if ($.NETWORK == $.Network.Mainnet || $.NETWORK == $.Network.Kovan) {
			if (_token == $.DAI || _token == $.USDC) {
				return DydxFlashLoanAbstraction._requestFlashLoan(_token, _netAmount, _context);
			}
		}
		return AaveFlashLoanAbstraction._requestFlashLoan(_token, _netAmount, _context);
	}

	function _paybackFlashLoan(address _token, uint256 _grossAmount) internal
	{
		if ($.NETWORK == $.Network.Mainnet || $.NETWORK == $.Network.Kovan) {
			if (_token == $.DAI || _token == $.USDC) {
				DydxFlashLoanAbstraction._paybackFlashLoan(_token, _grossAmount);
				return;
			}
		}
		AaveFlashLoanAbstraction._paybackFlashLoan(_token, _grossAmount);
	}
}
