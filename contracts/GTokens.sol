// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { GCTokenType1 } from "./GCTokenType1.sol";
import { GCTokenType2 } from "./GCTokenType2.sol";

import { $ } from "./network/$.sol";

/**
 * @notice Definition of gcDAI. As a gcToken Type 1, it uses cDAI as reserve
 * and employs leverage to maximize returns.
 */
contract gcDAI is GCTokenType1
{
	constructor ()
		GCTokenType1("growth cDAI", "gcDAI", 8, $.GRO, $.cDAI, $.COMP) public
	{
	}
}

/**
 * @notice Definition of gcUSDC. As a gcToken Type 1, it uses cUSDC as reserve
 * and employs leverage to maximize returns.
 */
contract gcUSDC is GCTokenType1
{
	constructor ()
		GCTokenType1("growth cUSDC", "gcUSDC", 8, $.GRO, $.cUSDC, $.COMP) public
	{
	}
}
