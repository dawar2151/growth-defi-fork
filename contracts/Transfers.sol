// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library Transfers
{
	using SafeERC20 for IERC20;

	function _getBalance(address _token) internal view returns (uint256 _balance)
	{
		return IERC20(_token).balanceOf(address(this));
	}

	function _pullFunds(address _token, address _from, uint256 _amount) internal
	{
		IERC20(_token).safeTransferFrom(_from, address(this), _amount);
	}

	function _pushFunds(address _token, address _to, uint256 _amount) internal
	{
		IERC20(_token).safeTransfer(_to, _amount);
	}

	function _approveFunds(address _token, address _to, uint256 _amount) internal
	{
		IERC20(_token).safeApprove(_to, _amount);
	}
}
