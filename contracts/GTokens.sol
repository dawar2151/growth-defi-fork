// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GCTokenBase } from "./GCTokenBase.sol";

import { $ } from "./network/$.sol";

contract gcDAI is GCTokenBase
{
	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 8, $.GRO, $.COMP, $.cDAI) public
	{
	}
}
