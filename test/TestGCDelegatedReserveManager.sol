// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Assert } from "truffle/Assert.sol";
import { DeployedAddresses } from "truffle/DeployedAddresses.sol";

import { Env } from "./Env.sol";

import { GCDelegatedReserveManager } from "../contracts/GCDelegatedReserveManager.sol";
import { G } from "../contracts/G.sol";

contract TestGCDelegatedReserveManager is Env
{
	using GCDelegatedReserveManager for GCDelegatedReserveManager.Self;

	GCDelegatedReserveManager.Self drm;

	constructor () public
	{
		address gcDAI = DeployedAddresses.gcDAI();
		drm.init(cWBTC, WBTC, COMP, gcDAI);

		address exchange = DeployedAddresses.GSushiswapExchange();
		drm.setExchange(exchange);
	}

	function test01() public
	{
		_burnAll(COMP);
		_burnAll(WBTC);
		_mint(COMP, 3e18);

		Assert.equal(_getBalance(COMP), 3e18, "COMP balance must be 3e18");
		Assert.equal(_getBalance(WBTC), 0e8, "WBTC balance must be 0e8");

		drm._convertMiningToUnderlying(2e18);

		Assert.equal(_getBalance(COMP), 1e18, "COMP balance must be 1e18");
		Assert.isAbove(_getBalance(WBTC), 0e8, "WBTC balance must be above 0e8");
	}

	function test02() public
	{
		_burnAll(COMP);
		_burnAll(WBTC);
		_burnAll(cWBTC);

		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(WBTC), 0e8, "WBTC balance must be 0e8");
		Assert.equal(_getBalance(cWBTC), 0e8, "cWBTC balance must be 0e8");

		drm._gulpMiningAssets();

		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(WBTC), 0e8, "WBTC balance must be 0e8");
		Assert.equal(_getBalance(cWBTC), 0e8, "cWBTC balance must be 0e8");
	}

	function test03() public
	{
		_burnAll(COMP);
		_burnAll(WBTC);
		_burnAll(cWBTC);
		_mint(COMP, 5e18);

		Assert.equal(_getBalance(COMP), 5e18, "COMP balance must be 5e18");
		Assert.equal(_getBalance(WBTC), 0e8, "WBTC balance must be 0e8");
		Assert.equal(_getBalance(cWBTC), 0e8, "cWBTC balance must be 0e8");

		drm.setMiningGulpRange(0e18, 100e18);
		drm._gulpMiningAssets();

		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(WBTC), 0e8, "WBTC balance must be 0e8");
		Assert.isAbove(_getBalance(cWBTC), 0e8, "cWBTC balance must be above 0e8");
	}

	function test04() public
	{
		_burnAll(COMP);
		_burnAll(WBTC);
		_burnAll(cWBTC);
		_mint(COMP, 5e18);

		Assert.equal(_getBalance(COMP), 5e18, "COMP balance must be 5e18");
		Assert.equal(_getBalance(WBTC), 0e8, "WBTC balance must be 0e8");
		Assert.equal(_getBalance(cWBTC), 0e8, "cWBTC balance must be 0e8");

		drm.setMiningGulpRange(0e18, 1e18);

		uint256 _rounds = 0;
		while (_getBalance(COMP) > 0) {
			drm._gulpMiningAssets();
			_rounds++;
		}

		Assert.equal(_getBalance(COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(WBTC), 0e8, "WBTC balance must be 0e8");
		Assert.isAbove(_getBalance(cWBTC), 0e8, "cWBTC balance must be above 0e8");
		Assert.equal(_rounds, 5, "rounds be 5");
	}
}
