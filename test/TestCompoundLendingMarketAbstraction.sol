// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Assert, AssertAddress } from "truffle/Assert.sol";

import { Env } from "./Env.sol";
import { Addresses } from "../contracts/Addresses.sol";
import { GCFormulae, CompoundLendingMarketAbstraction } from "../contracts/GCTokenBase.sol";

contract TestCompoundLendingMarketAbstraction is Env, GCFormulae, CompoundLendingMarketAbstraction(Addresses.cDAI)
{
	function test01() public
	{
		AssertAddress.equal(_getUnderlyingToken(Addresses.cDAI), Addresses.DAI, "DAI must be the underlying of cDAI");
	}

	function test02() public
	{
		_returnFullTokenBalance(Addresses.DAI);
		_returnFullTokenBalance(Addresses.cDAI);
		_mintTokenBalance(Addresses.DAI, 100e18);
		Assert.equal(_getBalance(Addresses.DAI), 100e18, "DAI balance must be 100e18");
		Assert.equal(_getBalance(Addresses.cDAI), 0e8, "cDAI balance must be 0e8");

		uint256 _amountcDAI = _calcCostFromUnderlyingCost(100e18, _fetchExchangeRate(Addresses.cDAI));

		_safeLend(Addresses.cDAI, 100e18);

		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(Addresses.cDAI), _amountcDAI, "cDAI balance must match");
		Assert.isAbove(_fetchLendAmount(Addresses.cDAI), 99999e15, "DAI lend balance must be above 99999e15");
	}

	function test03() public
	{
		_returnFullTokenBalance(Addresses.DAI);
		_returnFullTokenBalance(Addresses.cDAI);
		_mintTokenBalance(Addresses.cDAI, 5000e8);
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(Addresses.cDAI), 5000e8, "cDAI balance must be 5000e8");

		uint256 _amountDAI = _calcUnderlyingCostFromCost(5000e8, _fetchExchangeRate(Addresses.cDAI));
		uint256 _amountcDAI = _calcCostFromUnderlyingCost(_amountDAI, _fetchExchangeRate(Addresses.cDAI));

		_safeRedeem(Addresses.cDAI, _amountDAI);

		Assert.equal(_getBalance(Addresses.cDAI), uint256(5000e8).sub(_amountcDAI), "cDAI balance must be 0e8");
		Assert.equal(_getBalance(Addresses.DAI), _amountDAI, "DAI balance must match");
	}

	function test04() public
	{
		_returnFullTokenBalance(Addresses.DAI);
		_returnFullTokenBalance(Addresses.cDAI);
		_returnFullTokenBalance(Addresses.USDC);
		_returnFullTokenBalance(Addresses.cUSDC);
		_mintTokenBalance(Addresses.DAI, 100e18);
		Assert.equal(_getBalance(Addresses.DAI), 100e18, "DAI balance must be 100e18");
		Assert.equal(_getBalance(Addresses.cDAI), 0e8, "cDAI balance must be 0e8");
		Assert.equal(_getBalance(Addresses.USDC), 0e6, "USDC balance must be 0e6");
		Assert.equal(_getBalance(Addresses.cUSDC), 0e8, "cUSDC balance must be 0e8");

		uint256 _amountcDAI = _calcCostFromUnderlyingCost(100e18, _fetchExchangeRate(Addresses.cDAI));

		_safeLend(Addresses.cDAI, 100e18);

		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");
		Assert.equal(_getBalance(Addresses.cDAI), _amountcDAI, "cDAI balance must match");
		Assert.isAbove(_fetchLendAmount(Addresses.cDAI), 99999e15, "DAI lend balance must be above 99999e15");

		_safeBorrow(Addresses.cUSDC, 50e6);

		Assert.equal(_getBalance(Addresses.USDC), 50e6, "USDC balance must be 50e6");
		Assert.equal(_getBalance(Addresses.cUSDC), 0e8, "cUSDC balance must be 0e8");
		Assert.equal(_fetchBorrowAmount(Addresses.cUSDC), 50e6, "USDC borrow balance must be 50e6");

		_safeRepay(Addresses.cUSDC, 50e6);

		Assert.equal(_getBalance(Addresses.USDC), 0e6, "USDC balance must be 0e6");
		Assert.equal(_getBalance(Addresses.cUSDC), 0e8, "cUSDC balance must be 0e8");
		Assert.equal(_fetchBorrowAmount(Addresses.cUSDC), 0e6, "USDC borrow balance must be 0e6");

		_safeRedeem(Addresses.cDAI, 100e18);

		Assert.equal(_getBalance(Addresses.DAI), 100e18, "DAI balance must be 100e18");
		Assert.equal(_getBalance(Addresses.cDAI), 0e8, "cDAI balance must be 0e8");
		Assert.equal(_fetchLendAmount(Addresses.cDAI), 0e18, "DAI lend balance must be 0e18");
	}

	function test05() public
	{
		_safeLend(Addresses.cDAI, 0e18);
	}

	function test06() public
	{
		_safeRedeem(Addresses.cDAI, 0e18);
	}

	function test07() public
	{
		_safeBorrow(Addresses.cUSDC, 0e6);
	}

	function test08() public
	{
		_safeRepay(Addresses.cUSDC, 0e6);
	}
}
