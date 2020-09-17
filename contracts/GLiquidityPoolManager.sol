// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { BalancerLiquidityPoolAbstraction } from "./BalancerLiquidityPoolAbstraction.sol";

contract GLiquidityPoolManager is BalancerLiquidityPoolAbstraction
{
	enum State { Created, Allocated, Migrating, Migrated }

	uint256 constant DEFAULT_BURNING_RATE = 5e15; // 0.5%
	uint256 constant BURNING_INTERVAL = 7 days;
	uint256 constant MIGRATION_INTERVAL = 7 days;

	address private immutable stakesToken;
	address private immutable sharesToken;

	State private state = State.Created;
	address private liquidityPool = address(0);

	uint256 private burningRate = DEFAULT_BURNING_RATE;
	uint256 private lastBurningTime = 0;

	address private migrationRecipient = address(0);
	uint256 private migrationUnlockTime = uint256(-1);

	constructor (address _stakesToken, address _sharesToken) internal
	{
		stakesToken = _stakesToken;
		sharesToken = _sharesToken;
	}

	function _hasPool() internal view returns (bool _hasMigrated)
	{
		return state == State.Allocated || state == State.Migrating;
	}

	function _gulpPoolAssets() internal
	{
		if (!_hasPool()) return;
		_joinPool(liquidityPool, stakesToken, _getBalance(stakesToken));
		_joinPool(liquidityPool, sharesToken, _getBalance(sharesToken));
	}

	function _getLiquidityPool() internal view returns (address _liquidityPool)
	{
		return liquidityPool;
	}

	function _getBurningRate() internal view returns (uint256 _burningRate)
	{
		return burningRate;
	}

	function _getLastBurningTime() internal view returns (uint256 _lastBurningTime)
	{
		return lastBurningTime;
	}

	function _getMigrationRecipient() internal view returns (address _migrationRecipient)
	{
		return migrationRecipient;
	}

	function _getMigrationUnlockTime() internal view returns (uint256 _migrationUnlockTime)
	{
		return migrationUnlockTime;
	}

	function _setBurningRate(uint256 _burningRate) internal
	{
		require(_burningRate <= 1e18, "invalid rate");
		burningRate = _burningRate;
	}

	function _burnPoolPortion() internal returns (uint256 _stakesAmount, uint256 _sharesAmount)
	{
		require(_hasPool(), "pool not available");
		require(now > lastBurningTime + BURNING_INTERVAL, "must wait lock interval");
		lastBurningTime = now;
		return _exitPool(liquidityPool, burningRate);
	}

	function _allocatePool(uint256 _stakesAmount, uint256 _sharesAmount) internal
	{
		require(state == State.Created, "pool cannot be allocated");
		state = State.Allocated;
		liquidityPool = _createPool(stakesToken, _stakesAmount, sharesToken, _sharesAmount);
	}

	function _initiatePoolMigration(address _migrationRecipient) internal
	{
		require(state == State.Allocated, "pool not allocated");
		state = State.Migrating;
		migrationRecipient = _migrationRecipient;
		migrationUnlockTime = now + MIGRATION_INTERVAL;
	}

	function _cancelPoolMigration() internal returns (address _migrationRecipient)
	{
		require(state == State.Migrating, "migration not initiated");
		_migrationRecipient = migrationRecipient;
		state = State.Allocated;
		migrationRecipient = address(0);
		migrationUnlockTime = uint256(-1);
		return _migrationRecipient;
	}

	function _completePoolMigration() internal returns (address _migrationRecipient, uint256 _stakesAmount, uint256 _sharesAmount)
	{
		require(state == State.Migrating, "migration not initiated");
		require(now >= migrationUnlockTime, "must wait lock interval");
		state = State.Migrated;
		(_stakesAmount, _sharesAmount) = _exitPool(liquidityPool, 1e18);
		return (migrationRecipient, _stakesAmount, _sharesAmount);
	}
}
