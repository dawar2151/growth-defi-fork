// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Assert, AssertAddress } from "truffle/Assert.sol";

import { Env } from "./Env.sol";

import { GCFormulae } from "../contracts/GCFormulae.sol";

import { CompoundLendingMarketAbstraction } from "../contracts/modules/CompoundLendingMarketAbstraction.sol";

contract TestCompoundLendingMarketAbstraction is Env
{
	constructor () public
	{
		CompoundLendingMarketAbstraction._safeEnter(cDAI);
	}

	function test01() public
	{
		AssertAddress.equal(CompoundLendingMarketAbstraction._getUnderlyingToken(cDAI), DAI, "DAI must be the underlying of cDAI");
		AssertAddress.equal(CompoundLendingMarketAbstraction._getUnderlyingToken(cUSDC), USDC, "USDC must be the underlying of cUSDC");
		AssertAddress.equal(CompoundLendingMarketAbstraction._getUnderlyingToken(cETH), WETH, "WETH must be the underlying of cETH");
		AssertAddress.equal(CompoundLendingMarketAbstraction._getUnderlyingToken(cWBTC), WBTC, "WBTC must be the underlying of cWBTC");
	}

	function test02() public
	{
		_burnAll(DAI);
		_burnAll(cDAI);
		_mint(DAI, 100e18);
		Assert.equal(_getBalance(DAI), 100e18, "DAI balance must be 100e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");

		uint256 _exchangeRate = CompoundLendingMarketAbstraction._fetchExchangeRate(cDAI);
		uint256 _amountcDAI = GCFormulae._calcCostFromUnderlyingCost(100e18, _exchangeRate);

		CompoundLendingMarketAbstraction._safeLend(cDAI, 100e18);

		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(cDAI), _amountcDAI, "cDAI balance must match");
		Assert.isAbove(CompoundLendingMarketAbstraction._fetchLendAmount(cDAI), 99999e15, "DAI lend balance must be above 99999e15");
	}

	function test03() public
	{
		_burnAll(DAI);
		_burnAll(cDAI);
		_mint(cDAI, 5000e8);
		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(cDAI), 5000e8, "cDAI balance must be 5000e8");

		uint256 _exchangeRate = CompoundLendingMarketAbstraction._fetchExchangeRate(cDAI);
		uint256 _amountDAI = GCFormulae._calcUnderlyingCostFromCost(5000e8, _exchangeRate);
		uint256 _amountcDAI = GCFormulae._calcCostFromUnderlyingCost(_amountDAI, _exchangeRate);

		CompoundLendingMarketAbstraction._safeRedeem(cDAI, _amountDAI);

		Assert.equal(_getBalance(cDAI), uint256(5000e8).sub(_amountcDAI), "cDAI balance must be consistent");
		Assert.equal(_getBalance(DAI), _amountDAI, "DAI balance must match");
	}

	function test04() public
	{
		_burnAll(DAI);
		_burnAll(cDAI);
		_burnAll(USDC);
		_burnAll(cUSDC);
		_mint(DAI, 100e18);
		Assert.equal(_getBalance(DAI), 100e18, "DAI balance must be 100e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");
		Assert.equal(_getBalance(USDC), 0e6, "USDC balance must be 0e6");
		Assert.equal(_getBalance(cUSDC), 0e8, "cUSDC balance must be 0e8");

		uint256 _exchangeRate = CompoundLendingMarketAbstraction._fetchExchangeRate(cDAI);
		uint256 _amountcDAI = GCFormulae._calcCostFromUnderlyingCost(100e18, _exchangeRate);

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
		CompoundLendingMarketAbstraction._safeLend(cUSDC, 0e18);
		CompoundLendingMarketAbstraction._safeLend(cETH, 0e18);
		CompoundLendingMarketAbstraction._safeLend(cWBTC, 0e18);
	}

	function test06() public
	{
		CompoundLendingMarketAbstraction._safeRedeem(cDAI, 0e18);
		CompoundLendingMarketAbstraction._safeRedeem(cUSDC, 0e18);
		CompoundLendingMarketAbstraction._safeRedeem(cETH, 0e18);
		CompoundLendingMarketAbstraction._safeRedeem(cWBTC, 0e18);
	}

	function test07() public
	{
		CompoundLendingMarketAbstraction._safeBorrow(cDAI, 0e8);
		CompoundLendingMarketAbstraction._safeBorrow(cUSDC, 0e8);
		CompoundLendingMarketAbstraction._safeBorrow(cETH, 0e8);
		CompoundLendingMarketAbstraction._safeBorrow(cWBTC, 0e8);
	}

	function test08() public
	{
		CompoundLendingMarketAbstraction._safeRepay(cDAI, 0e8);
		CompoundLendingMarketAbstraction._safeRepay(cUSDC, 0e8);
		CompoundLendingMarketAbstraction._safeRepay(cETH, 0e8);
		CompoundLendingMarketAbstraction._safeRepay(cWBTC, 0e8);
	}

	function test09() public
	{
		_burnAll(DAI);
		_burnAll(cDAI);
		_mint(DAI, 100e18);

		Assert.equal(_getBalance(DAI), 100e18, "DAI balance must be 100e18");
		Assert.equal(_getBalance(cDAI), 0e8, "cDAI balance must be 0e8");

		CompoundLendingMarketAbstraction._safeLend(cDAI, 100e18);

		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");

		CompoundLendingMarketAbstraction._safeBorrow(cDAI, 70e18);

		Assert.equal(_getBalance(DAI), 70e18, "DAI balance must be 70e18");

		CompoundLendingMarketAbstraction._safeLend(cDAI, 70e18);

		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");

		CompoundLendingMarketAbstraction._safeBorrow(cDAI, 40e18);

		Assert.equal(_getBalance(DAI), 40e18, "DAI balance must be 40e18");

		_mint(DAI, 70e18);

		Assert.equal(_getBalance(DAI), 110e18, "DAI balance must be 110e18");

		CompoundLendingMarketAbstraction._safeRepay(cDAI, 110e18);

		Assert.equal(_getBalance(DAI), 0e18, "DAI balance must be 0e18");

		uint256 _lendAmount = CompoundLendingMarketAbstraction._getLendAmount(cDAI);
		Assert.isAtLeast(_lendAmount, 16999e16, "DAI balance must be at lest 16999e16");

		CompoundLendingMarketAbstraction._safeRedeem(cDAI, _lendAmount);

		Assert.equal(_getBalance(DAI), _lendAmount, "DAI balance must match lend amount");
	}
}
