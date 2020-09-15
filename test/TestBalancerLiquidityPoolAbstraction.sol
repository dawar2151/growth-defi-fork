// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Assert } from "truffle/Assert.sol";

import { Env } from "./Env.sol";
import { Addresses } from "../contracts/Addresses.sol";
import { Transfers, BalancerLiquidityPoolAbstraction } from "../contracts/GTokenBase.sol";

contract TestBalancerLiquidityPoolAbstraction is Env, Transfers, BalancerLiquidityPoolAbstraction
{
	function test01() public
	{
		_returnFullTokenBalance(Addresses.GRO);
		_returnFullTokenBalance(Addresses.DAI);
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

		_exitPool(_pool, 0e18);

		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");

		_exitPool(_pool, 1e18);

		Assert.equal(_getBalance(Addresses.GRO), 833015029829494720, "GRO balances must be 833015029829494720");
		Assert.equal(_getBalance(Addresses.DAI), 9996180357953936640, "DAI balances must be 9996180357953936640");
	}

	function test02() public
	{
		_returnFullTokenBalance(Addresses.GRO);
		_returnFullTokenBalance(Addresses.DAI);
		_mintTokenBalance(Addresses.GRO, 10e18);
		_mintTokenBalance(Addresses.DAI, 100e18);
		Assert.equal(_getBalance(Addresses.GRO), 10e18, "GRO balance must be 10e18");
		Assert.equal(_getBalance(Addresses.DAI), 100e18, "DAI balance must be 100e18");

		address _pool = _createPool(Addresses.GRO, 10e18, Addresses.DAI, 100e18);

		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");

		_returnFullTokenBalance(_pool);

		_mintTokenBalance(Addresses.DAI, 51e18);
		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 51e18, "DAI balance must be 51e18");

		_joinPool(_pool, Addresses.DAI, 51e18);

		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 1e18, "DAI balance must be 1e18");
	}

	function test03() public
	{
		_returnFullTokenBalance(Addresses.GRO);
		_returnFullTokenBalance(Addresses.DAI);
		_mintTokenBalance(Addresses.GRO, 10e18);
		_mintTokenBalance(Addresses.DAI, 100e18);
		Assert.equal(_getBalance(Addresses.GRO), 10e18, "GRO balance must be 10e18");
		Assert.equal(_getBalance(Addresses.DAI), 100e18, "DAI balance must be 100e18");

		address _pool = _createPool(Addresses.GRO, 10e18, Addresses.DAI, 100e18);

		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");

		_exitPool(_pool, 1e18);

		Assert.equal(_getBalance(Addresses.GRO), 10e18, "GRO balance must be 10e18");
		Assert.equal(_getBalance(Addresses.DAI), 100e18, "DAI balance must be 100e18");
	}

	function test04() public
	{
		_returnFullTokenBalance(Addresses.GRO);
		_returnFullTokenBalance(Addresses.DAI);
		_mintTokenBalance(Addresses.GRO, 1e6);
		_mintTokenBalance(Addresses.DAI, 1e6);
		Assert.equal(_getBalance(Addresses.GRO), 1e6, "GRO balance must be 1e6");
		Assert.equal(_getBalance(Addresses.DAI), 1e6, "DAI balance must be 1e6");

		address _pool = _createPool(Addresses.GRO, 1e6, Addresses.DAI, 1e6);

		Assert.equal(_getBalance(Addresses.GRO), 0e18, "GRO balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");

		_exitPool(_pool, 1e18);

		Assert.equal(_getBalance(Addresses.GRO), 1e6, "GRO balance must be 1e6");
		Assert.equal(_getBalance(Addresses.DAI), 1e6, "DAI balance must be 1e6");

		_joinPool(_pool, Addresses.DAI, 1e6);

		Assert.equal(_getBalance(Addresses.GRO), 1e6, "GRO balance must be 1e6");
		Assert.equal(_getBalance(Addresses.DAI), 1e6, "DAI balance must be 1e6");
	}
}
