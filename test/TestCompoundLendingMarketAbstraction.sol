// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Assert, AssertAddress } from "truffle/Assert.sol";

import { Env } from "./Env.sol";

import { GCFormulae } from "../contracts/GCFormulae.sol";

import { CompoundLendingMarketAbstraction } from "../contracts/modules/CompoundLendingMarketAbstraction.sol";

contract TestCompoundLendingMarketAbstraction is Env
{
	constructor () public {
		CompoundLendingMarketAbstraction._safeEnter(cDAI);
	}

	function test01() public
	{
		AssertAddress.equal(CompoundLendingMarketAbstraction._getUnderlyingToken(cDAI), DAI, "DAI must be the underlying of cDAI");
	}

	function test02() public
	{
		_returnFullTokenBalance(DAI);
		_returnFullTokenBalance(cDAI);
		_mintTokenBalance(DAI, 100e18);
		Assert.equal(_getBalance(DAI), 100e18, "DAI balance must be 100e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");

		uint256 _amountcDAI = GCFormulae._calcCostFromUnderlyingCost(100e18, CompoundLendingMarketAbstraction._fetchExchangeRate(cDAI));

		CompoundLendingMarketAbstraction._safeLend(cDAI, 100e18);

		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(cDAI), _amountcDAI, "cDAI balance must match");
		Assert.isAbove(CompoundLendingMarketAbstraction._fetchLendAmount(cDAI), 99999e15, "DAI lend balance must be above 99999e15");
	}

	function test03() public
	{
		_returnFullTokenBalance(DAI);
		_returnFullTokenBalance(cDAI);
		_mintTokenBalance(cDAI, 5000e8);
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(cDAI), 5000e8, "cDAI balance must be 5000e8");

		uint256 _amountDAI = GCFormulae._calcUnderlyingCostFromCost(5000e8, CompoundLendingMarketAbstraction._fetchExchangeRate(cDAI));
		uint256 _amountcDAI = GCFormulae._calcCostFromUnderlyingCost(_amountDAI, CompoundLendingMarketAbstraction._fetchExchangeRate(cDAI));

		CompoundLendingMarketAbstraction._safeRedeem(cDAI, _amountDAI);

		Assert.equal(_getBalance(cDAI), uint256(5000e8).sub(_amountcDAI), "cDAI balance must be 0e8");
		Assert.equal(_getBalance(DAI), _amountDAI, "DAI balance must match");
	}

	function test04() public
	{
		_returnFullTokenBalance(DAI);
		_returnFullTokenBalance(cDAI);
		_returnFullTokenBalance(USDC);
		_returnFullTokenBalance(cUSDC);
		_mintTokenBalance(DAI, 100e18);
		Assert.equal(_getBalance(DAI), 100e18, "DAI balance must be 100e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");
		Assert.equal(_getBalance(USDC), 0e6, "USDC balance must be 0e6");
		Assert.equal(_getBalance(cUSDC), 0e8, "cUSDC balance must be 0e8");

		uint256 _amountcDAI = GCFormulae._calcCostFromUnderlyingCost(100e18, CompoundLendingMarketAbstraction._fetchExchangeRate(cDAI));

		CompoundLendingMarketAbstraction._safeLend(cDAI, 100e18);

		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(cDAI), _amountcDAI, "cDAI balance must match");
		Assert.isAbove(CompoundLendingMarketAbstraction._fetchLendAmount(cDAI), 99999e15, "DAI lend balance must be above 99999e15");

		CompoundLendingMarketAbstraction._safeBorrow(cUSDC, 50e6);

		Assert.equal(_getBalance(USDC), 50e6, "USDC balance must be 50e6");
		Assert.equal(_getBalance(cUSDC), 0e8, "cUSDC balance must be 0e8");
		Assert.equal(CompoundLendingMarketAbstraction._fetchBorrowAmount(cUSDC), 50e6, "USDC borrow balance must be 50e6");

		CompoundLendingMarketAbstraction._safeRepay(cUSDC, 50e6);

		Assert.equal(_getBalance(USDC), 0e6, "USDC balance must be 0e6");
		Assert.equal(_getBalance(cUSDC), 0e8, "cUSDC balance must be 0e8");
		Assert.equal(CompoundLendingMarketAbstraction._fetchBorrowAmount(cUSDC), 0e6, "USDC borrow balance must be 0e6");

		CompoundLendingMarketAbstraction._safeRedeem(cDAI, 100e18);

		Assert.equal(_getBalance(DAI), 100e18, "DAI balance must be 100e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");
		Assert.equal(CompoundLendingMarketAbstraction._fetchLendAmount(cDAI), 0e18, "DAI lend balance must be 0e18");
	}

	function test05() public
	{
		CompoundLendingMarketAbstraction._safeLend(cDAI, 0e18);
	}

	function test06() public
	{
		CompoundLendingMarketAbstraction._safeRedeem(cDAI, 0e18);
	}

	function test07() public
	{
		CompoundLendingMarketAbstraction._safeBorrow(cUSDC, 0e6);
	}

	function test08() public
	{
		CompoundLendingMarketAbstraction._safeRepay(cUSDC, 0e6);
	}
}
