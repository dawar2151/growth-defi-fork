// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { GCTokenBase } from "./GCTokenBase.sol";
import { GCDelegatedTokenBase } from "./GCDelegatedTokenBase.sol";

import { $ } from "./network/$.sol";

contract gcDAI is GCTokenBase
{
	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 8, $.GRO, $.cDAI, $.COMP) public
	{
	}
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

contract gcWETH is GCDelegatedTokenBase
{
	constructor ()
		GCDelegatedTokenBase("growth cWETH", "gcWETH", 8, $.GRO, $.cWETH, $.COMP, $.gcDAI) public
	{
	}
}

contract gcWBTC is GCDelegatedTokenBase
{
	constructor ()
		GCDelegatedTokenBase("growth cWBTC", "gcWBTC", 8, $.GRO, $.cWBTC, $.COMP, $.gcDAI) public
	{
	}
}

contract gcBAT is GCDelegatedTokenBase
{
	constructor ()
		GCDelegatedTokenBase("growth cBAT", "gcBAT", 8, $.GRO, $.cBAT, $.COMP, $.gcDAI) public
	{
	}
}

contract gcZRX is GCDelegatedTokenBase
{
	constructor ()
		GCDelegatedTokenBase("growth cZRX", "gcZRX", 8, $.GRO, $.cZRX, $.COMP, $.gcDAI) public
	{
	}
}
