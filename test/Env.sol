// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { _Addresses } from "../contracts/Addresses.sol";
import { Transfers } from "../contracts/Transfers.sol";
import { Router02 } from "../contracts/interop/UniswapV2.sol";

contract Env is _Addresses
{
	using SafeMath for uint256;

	uint256 public initialBalance = 5 ether;

	receive() external payable {}

	function _getBalance(address _token) internal view returns (uint256 _amount)
	{
		return Transfers._getBalance(_token);
	}

	function _mintTokenBalance(address _token, uint256 _amount) internal
	{
		address _router = UniswapV2_ROUTER02;
		address[] memory _path = new address[](2);
		_path[0] = Router02(_router).WETH();
		_path[1] = _token;
		Router02(_router).swapETHForExactTokens{value: address(this).balance}(_amount, _path, address(this), block.timestamp);
	}

	function _returnFullTokenBalance(address _token) internal
	{
		address _from = msg.sender;
		Transfers._pushFunds(_token, _from, Transfers._getBalance(_token));
	}
}
