// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Assert } from "truffle/Assert.sol";

import { Env } from "./Env.sol";
import { Conversions } from "../contracts/Conversions.sol";

contract TestConversions is Env
{
	function test01() public
	{
		_returnFullTokenBalance(USDC);
		_returnFullTokenBalance(DAI);
		Assert.equal(_getBalance(USDC), 0e6, "USDC balance must be 0e6");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");

		Conversions._convertFundsUSDCToDAI(0e6);

		Assert.equal(_getBalance(USDC), 0e6, "USDC balance must be 0e6");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
	}

	function test02() public
	{
		_returnFullTokenBalance(USDC);
		_returnFullTokenBalance(DAI);
		Assert.equal(_getBalance(USDC), 0e6, "USDC balance must be 0e6");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");

		_mintTokenBalance(USDC, 100e6);
		Assert.equal(_getBalance(USDC), 100e6, "USDC balance must be 100e6");

		Conversions._convertFundsUSDCToDAI(80e6);
		Assert.equal(_getBalance(USDC), 20e6, "USDC balance must be 20e6");
		Assert.isAbove(_getBalance(DAI), 0e18, "DAI balance must be above 0e18");
	}

	function test03() public
	{
		_returnFullTokenBalance(USDC);
		_returnFullTokenBalance(DAI);
		Assert.equal(_getBalance(USDC), 0e6, "USDC balance must be 0e6");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");

		_mintTokenBalance(USDC, 333e6);
		Assert.equal(_getBalance(USDC), 333e6, "USDC balance must be 333e6");

		Conversions._convertFundsUSDCToDAI(333e6);
		Assert.equal(_getBalance(USDC), 0e6, "USDC balance must be 0e6");
		Assert.isAbove(_getBalance(DAI), 0e18, "DAI balance must be above 0e18");
	}

	function test04() public
	{
		_returnFullTokenBalance(COMP);
		_returnFullTokenBalance(DAI);
		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");

		Conversions._convertFundsCOMPToDAI(0e18);
		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
	}

	function test05() public
	{
		_returnFullTokenBalance(COMP);
		_returnFullTokenBalance(DAI);
		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");

		_mintTokenBalance(COMP, 2e18);
		Assert.equal(_getBalance(COMP), 2e18, "COMP balance must be 2e18");

		Conversions._convertFundsCOMPToDAI(1e18);
		Assert.equal(_getBalance(COMP), 1e18, "COMP balance must be 1e18");
		Assert.isAbove(_getBalance(DAI), 0e18, "DAI balance must be above 0e18");
	}

	function test06() public
	{
		_returnFullTokenBalance(COMP);
		_returnFullTokenBalance(DAI);
		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");

		_mintTokenBalance(COMP, 3e18);
		Assert.equal(_getBalance(COMP), 3e18, "COMP balance must be 3e18");

		Conversions._convertFundsCOMPToDAI(3e18);
		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.isAbove(_getBalance(DAI), 0e18, "DAI balance must be above 0e18");
	}
}
