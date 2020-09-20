// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Assert } from "truffle/Assert.sol";

import { Env } from "./Env.sol";

import { GCLeveragedReserveManager } from "../contracts/GCLeveragedReserveManager.sol";
import { G } from "../contracts/G.sol";

contract TestGCLeveragedReserveManager is Env
{
	using GCLeveragedReserveManager for GCLeveragedReserveManager.Self;

	GCLeveragedReserveManager.Self lrm;

	constructor () public
	{
		lrm.init(COMP, cDAI, cUSDC, 100e18);
	}

	function test01() public
	{
		_burnAll(COMP);
		_burnAll(DAI);
		_burnAll(cDAI);

		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");

		lrm.gulpMiningAssets();

		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");
	}

	function test02() public
	{
		_burnAll(COMP);
		_burnAll(DAI);
		_burnAll(cDAI);
		_mint(DAI, 50e18);

		uint256 _amountCOMP = G.convertFunds(DAI, COMP, 40e18, 0);

		Assert.equal(_getBalance(COMP), _amountCOMP, "COMP balance must match");
		Assert.equal(_getBalance(DAI), 10e18, "DAI balance must be 10e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");

		lrm.gulpMiningAssets();

		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.isAbove(_getBalance(cDAI), 0e8, "cDAI balance must be above 0e8");
	}

	function test03() public
	{
		_burnAll(COMP);
		_burnAll(DAI);
		_burnAll(cDAI);
		_mint(DAI, 200e18);

		uint256 _amountCOMP = G.convertFunds(DAI, COMP, 200e18, 0);

		Assert.equal(_getBalance(COMP), _amountCOMP, "COMP balance must match");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");

		uint256 _rounds = 0;
		while (_getBalance(COMP) > 0) {
			lrm.gulpMiningAssets();
			_rounds++;
		}

		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.isAbove(_getBalance(cDAI), 0e8, "cDAI balance must be above 0e8");
		Assert.isAbove(_rounds, 1, "cDAI balance must be 0e8");
	}
}
