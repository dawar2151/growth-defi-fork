// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { G } from "./G.sol";

library GLiquidityPoolManager
{
	using GLiquidityPoolManager for GLiquidityPoolManager.Self;

	uint256 constant DEFAULT_BURNING_RATE = 5e15; // 0.5%
	uint256 constant BURNING_INTERVAL = 7 days;
	uint256 constant MIGRATION_INTERVAL = 7 days;

	enum State { Created, Allocated, Migrating, Migrated }

	struct Self {
		address stakesToken;
		address sharesToken;

		State state;
		address liquidityPool;

		uint256 burningRate;
		uint256 lastBurningTime;

		address migrationRecipient;
		uint256 migrationUnlockTime;
	}

	function init(Self storage _self, address _stakesToken, address _sharesToken) public
	{
		_self.stakesToken = _stakesToken;
		_self.sharesToken = _sharesToken;

		_self.state = State.Created;
		_self.liquidityPool = address(0);

		_self.burningRate = DEFAULT_BURNING_RATE;
		_self.lastBurningTime = 0;

		_self.migrationRecipient = address(0);
		_self.migrationUnlockTime = uint256(-1);
	}

	function hasPool(Self storage _self) public view returns (bool _poolAvailable)
	{
		return _self._hasPool();
	}

	function gulpPoolAssets(Self storage _self) public
	{
		if (!_self._hasPool()) return;
		G.joinPool(_self.liquidityPool, _self.stakesToken, G.getBalance(_self.stakesToken));
		G.joinPool(_self.liquidityPool, _self.sharesToken, G.getBalance(_self.sharesToken));
	}

	function setBurningRate(Self storage _self, uint256 _burningRate) public
	{
		require(_burningRate <= 1e18, "invalid rate");
		_self.burningRate = _burningRate;
	}

	function burnPoolPortion(Self storage _self) public returns (uint256 _stakesAmount, uint256 _sharesAmount)
	{
		require(_self._hasPool(), "pool not available");
		require(now >= _self.lastBurningTime + BURNING_INTERVAL, "must wait lock interval");
		_self.lastBurningTime = now;
		return G.exitPool(_self.liquidityPool, _self.burningRate);
	}

	function allocatePool(Self storage _self, uint256 _stakesAmount, uint256 _sharesAmount) public
	{
		require(_self.state == State.Created, "pool cannot be allocated");
		_self.state = State.Allocated;
		_self.liquidityPool = G.createPool(_self.stakesToken, _stakesAmount, _self.sharesToken, _sharesAmount);
	}

	function initiatePoolMigration(Self storage _self, address _migrationRecipient) public
	{
		require(_self.state == State.Allocated, "pool not allocated");
		_self.state = State.Migrating;
		_self.migrationRecipient = _migrationRecipient;
		_self.migrationUnlockTime = now + MIGRATION_INTERVAL;
	}

	function cancelPoolMigration(Self storage _self) public returns (address _migrationRecipient)
	{
		require(_self.state == State.Migrating, "migration not initiated");
		_migrationRecipient = _self.migrationRecipient;
		_self.state = State.Allocated;
		_self.migrationRecipient = address(0);
		_self.migrationUnlockTime = uint256(-1);
		return _migrationRecipient;
	}

	function completePoolMigration(Self storage _self) public returns (address _migrationRecipient, uint256 _stakesAmount, uint256 _sharesAmount)
	{
		require(_self.state == State.Migrating, "migration not initiated");
		require(now >= _self.migrationUnlockTime, "must wait lock interval");
		_self.state = State.Migrated;
		_migrationRecipient = _self.migrationRecipient;
		(_stakesAmount, _sharesAmount) = G.exitPool(_self.liquidityPool, 1e18);
		return (_migrationRecipient, _stakesAmount, _sharesAmount);
	}

	function _hasPool(Self storage _self) internal view returns (bool _poolAvailable)
	{
		return _self.state == State.Allocated || _self.state == State.Migrating;
	}
}
