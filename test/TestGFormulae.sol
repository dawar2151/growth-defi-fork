// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Assert } from "truffle/Assert.sol";

import { GFormulae } from "../contracts/gcDAI.sol";

contract TestGFormulae is GFormulae
{
	function test01() public
	{
		uint256 _cost1 = 101e18;
		uint256 _totalReserve = 1000e18;
		uint256 _totalSupply = 1000e18;
		uint256 _depositFee = 1e16;
		(uint256 _netShares, uint256 _feeShares1) = _calcDepositSharesFromCost(_cost1, _totalReserve, _totalSupply, _depositFee);
		Assert.equal(_netShares, 100e18, "net shares must be 100e18");
		(uint256 _cost2, uint256 _feeShares2) = _calcDepositCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee);
		Assert.equal(_cost1, _cost2, "costs must be equal");
		Assert.equal(_feeShares1, _feeShares2, "fee shares must be equal");
	}

	function test02() public
	{
		uint256 _grossShares1 = 100e18;
		uint256 _totalReserve = 1000e18;
		uint256 _totalSupply = 1000e18;
		uint256 _withdrawalFee = 1e16;
		(uint256 _cost, uint256 _feeShares1) = _calcWithdrawalCostFromShares(_grossShares1, _totalReserve, _totalSupply, _withdrawalFee);
		Assert.equal(_cost, 99e18, "cost must be 99e18");
		(uint256 _grossShares2, uint256 _feeShares2) = _calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
		Assert.equal(_grossShares1, _grossShares2, "gross shares must be equal");
		Assert.equal(_feeShares1, _feeShares2, "fee shares must be equal");
	}

	function test03() public
	{
		uint256 _cost1 = 100e18;
		uint256 _totalReserve = 1000e18;
		uint256 _totalSupply = 1000e18;
		uint256 _depositFee = 0e16;
		(uint256 _netShares, uint256 _feeShares1) = _calcDepositSharesFromCost(_cost1, _totalReserve, _totalSupply, _depositFee);
		Assert.equal(_netShares, 100e18, "net shares must be 100e18");
		(uint256 _cost2, uint256 _feeShares2) = _calcDepositCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee);
		Assert.equal(_cost1, _cost2, "costs must be equal");
		Assert.equal(_feeShares1, _feeShares2, "fee shares must be equal");
	}

	function test04() public
	{
		uint256 _grossShares1 = 100e18;
		uint256 _totalReserve = 1000e18;
		uint256 _totalSupply = 1000e18;
		uint256 _withdrawalFee = 0e16;
		(uint256 _cost, uint256 _feeShares1) = _calcWithdrawalCostFromShares(_grossShares1, _totalReserve, _totalSupply, _withdrawalFee);
		Assert.equal(_cost, 100e18, "cost must be 100e18");
		(uint256 _grossShares2, uint256 _feeShares2) = _calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
		Assert.equal(_grossShares1, _grossShares2, "gross shares must be equal");
		Assert.equal(_feeShares1, _feeShares2, "fee shares must be equal");
	}

	function test05() public
	{
		uint256 _cost1 = 101e18;
		uint256 _totalReserve = 2000e18;
		uint256 _totalSupply = 1000e18;
		uint256 _depositFee = 1e16;
		(uint256 _netShares, uint256 _feeShares1) = _calcDepositSharesFromCost(_cost1, _totalReserve, _totalSupply, _depositFee);
		Assert.equal(_netShares, 50e18, "net shares must be 50e18");
		(uint256 _cost2, uint256 _feeShares2) = _calcDepositCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee);
		Assert.equal(_cost1, _cost2, "costs must be equal");
		Assert.equal(_feeShares1, _feeShares2, "fee shares must be equal");
	}

	function test06() public
	{
		uint256 _grossShares1 = 100e18;
		uint256 _totalReserve = 2000e18;
		uint256 _totalSupply = 1000e18;
		uint256 _withdrawalFee = 1e16;
		(uint256 _cost, uint256 _feeShares1) = _calcWithdrawalCostFromShares(_grossShares1, _totalReserve, _totalSupply, _withdrawalFee);
		Assert.equal(_cost, 198e18, "cost must be 198e18");
		(uint256 _grossShares2, uint256 _feeShares2) = _calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
		Assert.equal(_grossShares1, _grossShares2, "gross shares must be equal");
		Assert.equal(_feeShares1, _feeShares2, "fee shares must be equal");
	}
}
