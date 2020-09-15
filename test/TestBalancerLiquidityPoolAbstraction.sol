// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Assert } from "truffle/Assert.sol";

import { Env } from "./Env.sol";
import { Addresses } from "../contracts/Addresses.sol";
import { Transfers, BalancerLiquidityPoolAbstraction } from "../contracts/gcDAI.sol";

contract TestBalancerLiquidityPoolAbstraction is Env, Transfers, BalancerLiquidityPoolAbstraction
{
	function test01() public
	{
		_returnFullTokenBalance(Addresses.GRO);
		_returnFullTokenBalance(Addresses.DAI);
		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");

		_mintTokenBalance(Addresses.GRO, 10e18);
		_mintTokenBalance(Addresses.DAI, 100e18);
		Assert.equal(_getBalance(Addresses.GRO), 10e18, "GRO balance must be 10e18");
		Assert.equal(_getBalance(Addresses.DAI), 100e18, "DAI balance must be 100e18");

		address _pool = _createPool(Addresses.GRO, 10e18, Addresses.DAI, 100e18);

		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");

		_returnFullTokenBalance(_pool);

		_joinPool(_pool, Addresses.DAI, 0e18);

		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");

		_mintTokenBalance(Addresses.DAI, 20e18);
		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 20e18, "DAI balance must be 20e18");

		_joinPool(_pool, Addresses.DAI, 20e18);

		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");

		_exitPool(_pool, 0e18, Addresses.GRO, Addresses.DAI);

		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");

		_exitPool(_pool, 1e18, Addresses.GRO, Addresses.DAI);

		Assert.equal(_getBalance(Addresses.GRO), 833015029829494720, "GRO balances must be 833015029829494720");
		Assert.equal(_getBalance(Addresses.DAI), 9996180357953936640, "DAI balances must be 9996180357953936640");
	}
}
