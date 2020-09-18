// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GCTokenBase } from "./GCTokenBase.sol";

import { Addresses } from "./modules/Addresses.sol";

contract gcDAI is GCTokenBase
{
	uint256 constant DEFAULT_LEVERAGE_ADJUSTMENT_AMOUNT = 1000e18; // 1000 DAI

	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 18, Addresses.GRO, Addresses.COMP, Addresses.cDAI, Addresses.cUSDC, DEFAULT_LEVERAGE_ADJUSTMENT_AMOUNT) public
	{
	}
}
