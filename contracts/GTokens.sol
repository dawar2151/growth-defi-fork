// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GCTokenBase } from "./GCTokenBase.sol";

import { $ } from "./network/$.sol";

contract gcDAI is GCTokenBase
{
	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 8, $.GRO, $.cDAI, $.COMP) public
	{
		setMiningGulpRange(20e18, 500e18);
	}
}

contract gcUSDC is GCTokenBase
{
	constructor ()
		GCTokenBase("growth cUSDC", "gcUSDC", 8, $.GRO, $.cUSDC, $.COMP) public
	{
		setMiningGulpRange(20e18, 500e18);
	}
}

contract gcUSDT is GCTokenBase
{
	constructor ()
		GCTokenBase("growth cUSDT", "gcUSDT", 8, $.GRO, $.cUSDT, $.COMP) public
	{
		setMiningGulpRange(20e18, 500e18);
	}
}
