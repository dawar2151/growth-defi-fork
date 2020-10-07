// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { GCTokenType1 } from "./GCTokenType1.sol";
import { GCTokenType2 } from "./GCTokenType2.sol";

import { $ } from "./network/$.sol";

contract gcDAI is GCTokenType1
{
	constructor ()
		GCTokenType1("growth cDAI", "gcDAI", 8, $.GRO, $.cDAI, $.COMP) public
	{
	}
}

contract gcUSDC is GCTokenType1
{
	constructor ()
		GCTokenType1("growth cUSDC", "gcUSDC", 8, $.GRO, $.cUSDC, $.COMP) public
	{
	}
}

contract gcUSDT is GCTokenType1
{
	constructor ()
		GCTokenType1("growth cUSDT", "gcUSDT", 8, $.GRO, $.cUSDT, $.COMP) public
	{
	}
}

contract gcETH is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cETH", "gcETH", 8, $.GRO, $.cETH, $.COMP, _growthToken) public
	{
	}

	receive() external payable {}
}

contract gcWBTC is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cWBTC", "gcWBTC", 8, $.GRO, $.cWBTC, $.COMP, _growthToken) public
	{
	}
}

contract gcBAT is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cBAT", "gcBAT", 8, $.GRO, $.cBAT, $.COMP, _growthToken) public
	{
	}
}

contract gcZRX is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cZRX", "gcZRX", 8, $.GRO, $.cZRX, $.COMP, _growthToken) public
	{
	}
}

contract gcUNI is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cUNI", "gcUNI", 8, $.GRO, $.cUNI, $.COMP, _growthToken) public
	{
	}
}
