// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GCTokenBase } from "./GCTokenBase.sol";

import { $ } from "./network/$.sol";

contract gcDAI is GCTokenBase
{
	uint256 constant DEFAULT_LEVERAGE_ADJUSTMENT_AMOUNT = 1000e18; // 1000 DAI

	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 8, $.GRO, $.COMP, $.cDAI, $.cUSDC, DEFAULT_LEVERAGE_ADJUSTMENT_AMOUNT) public
	{
	}
}
