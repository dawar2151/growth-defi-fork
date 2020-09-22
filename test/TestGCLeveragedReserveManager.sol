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
		lrm.init(COMP, cDAI);
	}

	function test01() public
	{
		_burnAll(COMP);
		_burnAll(DAI);
		_mint(COMP, 3e18);

		Assert.equal(_getBalance(COMP), 3e18, "COMP balance must be 3e18");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");

		lrm._convertMiningToUnderlying(2e18);

		Assert.equal(_getBalance(COMP), 1e18, "COMP balance must be 1e18");
		Assert.isAbove(_getBalance(DAI), 0e18, "DAI balance must be above 0e18");
	}

	function test02() public
	{
		uint256 _amount1 = lrm._calcConversionUnderlyingToMiningGivenMining(3e18);
		uint256 _amount2 = G.calcConversionInputFromOutput(DAI, COMP, 3e18);
		Assert.equal(_amount1, _amount2, "amounts must match");
	}

	function test03() public
	{
		uint256 _deathAmount = lrm._calcDeathAmount(1000000000e18);

		Assert.equal(_deathAmount, 750000000e18, "death amount must be 750000000e18");
	}

	function test04() public
	{
		uint256 _limitAmount = lrm._calcLimitAmount(1000000000e18);

		Assert.equal(_limitAmount, 690000000e18, "limit amount must be 690000000e18");
	}

	function test05() public
	{
		uint256 _idealAmount = lrm._calcIdealAmount(1000000000e18);

		Assert.equal(_idealAmount, 660000000e18, "ideal amount must be 660000000e18");
	}

	function test06() public
	{
		uint256 _deviationAmount = lrm._calcDeviationAmount(1000000000e18);

		Assert.equal(_deviationAmount, 7500000e18, "deviation amount must be 7500000e18");
	}
/*
	function test07() public
	{
		_burnAll(DAI);
		_burnAll(cDAI);
		_mint(DAI, 100e18);

		Assert.equal(_getBalance(DAI), 100e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");

		G.safeLend(cDAI, 100e18);

		uint256 _availableDAI = lrm._getAvailableUnderlying();

		Assert.isAtMost(_availableDAI, 69e18, "DAI available must be at most 69e18");

		_availableDAI = lrm._getAvailableBorrow();

		Assert.isAtMost(_availableDAI, 66e18, "DAI available must be at most 66e18");

		bool _success1 = G.borrow(DAI, 30e18);
		Assert.isTrue(_success1, "failure borrowing DAI");

		_availableDAI = lrm._getAvailableUnderlying();

		Assert.isAtMost(_availableDAI, 69e18 - 29e18, "DAI available must be at most 69e18 minus 30e6");

		_availableDAI = lrm._getAvailableBorrow();

		Assert.isAtMost(_availableDAI, 66e18 - 29e18, "DAI available must be at most 66e18 minus 30e6");

		bool _success2 = G.repay(DAI, 30e18);
		Assert.isTrue(_success2, "failure repaying DAI");

		G.safeRedeem(cDAI, 100e18);
	}

	function test08() public
	{
		_burnAll(DAI);
		_burnAll(cDAI);
		_mint(DAI, 1000e18);

		Assert.equal(_getBalance(DAI), 1000e18, "DAI balance must be 1000e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");

		G.safeLend(cDAI, 1000e18);

		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.isAbove(G.fetchLendAmount(cDAI), 99999e16, "DAI lend amount must be above 99999e16");
		Assert.equal(G.fetchBorrowAmount(cDAI), 0e18, "DAI borrow amount must be 0e6");

		lrm.setLeverageEnabled(true);
		bool _success = lrm.adjustLeverage();

		Assert.isTrue(_success, "failure leveraging");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.isAbove(G.fetchLendAmount(cDAI), 1000e18, "DAI balance must be above 1000e18");

		lrm.setLeverageEnabled(false);
		_success = lrm.adjustLeverage();

		Assert.isTrue(_success, "failure deleveraging");
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");

		Assert.equal(G.fetchBorrowAmount(cDAI), 0e18, "DAI borrow balance must be 0e18");

		G.safeRedeem(cDAI, G.fetchLendAmount(cDAI));

		Assert.isAbove(_getBalance(DAI), 999e18, "DAI amount must be above 999e18");
	}
*/
	function test09() public
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

	function test10() public
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

	function test11() public
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
		Assert.isAtLeast(_rounds, 1, "rounds be at least 1");
	}
}
