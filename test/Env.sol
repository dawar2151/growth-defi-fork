// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Addresses } from "../contracts/Addresses.sol";
import { Transfers } from "../contracts/Transfers.sol";
import { Router02 } from "../contracts/interop/UniswapV2.sol";

contract Env is Addresses, Transfers
{
	uint256 public initialBalance = 5 ether;

	receive() external payable {}

	function _mintTokenBalance(address _token, uint256 _amount) internal
	{
		Router02 _router = Router02(UniswapV2_ROUTER02);
		address[] memory _path = new address[](2);
		_path[0] = _router.WETH();
		_path[1] = _token;
		_router.swapETHForExactTokens{value: address(this).balance}(_amount, _path, address(this), block.timestamp);
	}

	function _returnFullTokenBalance(address _token) internal
	{
		address _from = msg.sender;
		_pushFunds(_token, _from, _getBalance(_token));
	}
}
