// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { Addresses } from "../contracts/Addresses.sol";
import { Router02 } from "../contracts/interop/UniswapV2.sol";

contract Env
{
	using SafeERC20 for IERC20;

	uint256 public initialBalance = 5 ether;

	receive() external payable {}

	function _mintTokenBalance(address _token, uint256 _amount) internal
	{
		Router02 _router = Router02(Addresses.UniswapV2_ROUTER02);
		address[] memory _path = new address[](2);
		_path[0] = _router.WETH();
		_path[1] = _token;
		_router.swapETHForExactTokens{value: address(this).balance}(_amount, _path, address(this), block.timestamp);
	}

	function _returnFullTokenBalance(address _token) internal
	{
		IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
	}
}
