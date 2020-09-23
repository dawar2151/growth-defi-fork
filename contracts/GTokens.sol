// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GCTokenBase } from "./GCTokenBase.sol";
/*
import { Router02 } from "../contracts/interop/UniswapV2.sol";
*/
import { $ } from "./network/$.sol";

contract gcDAI is GCTokenBase
{
	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 8, $.GRO, $.cDAI, $.COMP) public
	{
	}
/*
	receive() external payable {}

	function faucet(uint256 _amount) public payable {
		address payable _from = msg.sender;
		uint256 _value = msg.value;
		address _router = $.UniswapV2_ROUTER02;
		address[] memory _path = new address[](2);
		_path[0] = Router02(_router).WETH();
		_path[1] = $.cDAI;
		uint256 _spent = Router02(_router).swapETHForExactTokens{value: _value}(_amount, _path, _from, block.timestamp)[0];
		_from.transfer(_value - _spent);
	}
*/
}

contract gcUSDC is GCTokenBase
{
	constructor ()
		GCTokenBase("growth cUSDC", "gcUSDC", 8, $.GRO, $.cUSDC, $.COMP) public
	{
	}
}

contract gcUSDT is GCTokenBase
{
	constructor ()
		GCTokenBase("growth cUSDT", "gcUSDT", 8, $.GRO, $.cUSDT, $.COMP) public
	{
	}
}
