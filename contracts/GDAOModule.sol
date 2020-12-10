// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/EnumerableSet.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { GVoting } from "./GVoting.sol";
import { G } from "./G.sol";

import { Enum, Safe } from "./interop/Gnosis.sol";

contract GDAOModule is ReentrancyGuard
{
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;

	string public constant NAME = "GrowthDeFi DAO Module";
	string public constant VERSION = "0.0.1";

	uint256 constant VOTING_ROUND_INTERVAL = 1 days;

	uint256 constant SIGNING_OWNERS = 7;
	uint256 constant SIGNING_THRESHOLD = 4;

	address public immutable safe;
	address public immutable votingToken;

	bool private synced = false;
	uint256 private votingRound = 0;
	EnumerableSet.AddressSet private candidates;

	constructor (address _safe, address _votingToken) public
	{
		safe = _safe;
		votingToken = _votingToken;

		address[] memory _owners = Safe(_safe).getOwners();
		uint256 _ownersCount = _owners.length;
		for (uint256 _index = 0; _index < _ownersCount; _index++) {
			address _owner = _owners[_index];
			bool _success = candidates.add(_owner);
			assert(_success);
		}
	}

	function currentVotingRound() public view returns (uint256 _votingRound)
	{
		return block.timestamp.div(VOTING_ROUND_INTERVAL);
	}

	function timeToNextVotingRound() public view returns (uint256 _timeToNextVotingRound)
	{
		return block.timestamp.div(VOTING_ROUND_INTERVAL).add(1).mul(VOTING_ROUND_INTERVAL);
	}

	function hasPendingTurnOver() internal view returns (bool _hasPendingTurnOver)
	{
		uint256 _votingRound = block.timestamp.div(VOTING_ROUND_INTERVAL);
		return _votingRound > votingRound && !synced;
	}

	function candidateCount() public view returns (uint256 _count)
	{
		return candidates.length();
	}

	function candidateAt(uint256 _index) public view returns (address _candidate)
	{
		return candidates.at(_index);
	}

	function appointCandidate() public nonReentrant
	{
		address _candidate = msg.sender;
		_closeRound();
		require(!candidates.contains(_candidate), "candidate already eligible");
		require(_appointCandidate(_candidate), "candidate not eligible");
	}

	function turnOver() public nonReentrant
	{
		require(_closeRound(), "must wait next interval");
	}

	function _findLeastVoted() internal view returns (address _leastVoted, uint256 _leastVotes)
	{
		_leastVoted = address(0);
		_leastVotes = uint256(-1);
		uint256 _candidateCount = candidates.length();
		for (uint256 _index = 0; _index < _candidateCount; _index++) {
			address _candidate = candidates.at(_index);
			uint256 _votes = GVoting(votingToken).votes(_candidate);
			if (_votes < _leastVotes) {
				_leastVoted = _candidate;
				_leastVotes = _votes;
			}
		}
		return (_leastVoted, _leastVotes);
	}

	function _closeRound() internal returns (bool _success)
	{
		uint256 _votingRound = block.timestamp.div(VOTING_ROUND_INTERVAL);
		if (_votingRound > votingRound) {
			votingRound = _votingRound;
			_turnOver();
			return true;
		}
		return false;
	}

	function _appointCandidate(address _candidate) internal returns(bool _success)
	{
		uint256 _candidateCount = candidates.length();
		if (_candidateCount == SIGNING_OWNERS) {
			uint256 _votes = GVoting(votingToken).votes(_candidate);
			(address _leastVoted, uint256 _leastVotes) = _findLeastVoted();
			if (_leastVotes >= _votes) return false;
			candidates.remove(_leastVoted);
		}
		candidates.add(_candidate);
		synced = false;
		return true;
	}

	function _turnOver() internal
	{
		if (synced) return;
		uint256 _candidateCount = candidates.length();
		for (uint256 _index = 0; _index < _candidateCount; _index++) {
			address _candidate = candidates.at(_index);
			if (Safe(safe).isOwner(_candidate)) continue;
			bool _success = _addOwnerWithThreshold(_candidate, 1);
			assert(_success);
		}
		address[] memory _owners = Safe(safe).getOwners();
		uint256 _ownersCount = _owners.length;
		for (uint256 _index = 0; _index < _ownersCount; _index++) {
			address _owner = _owners[_index];
			if (candidates.contains(_owner)) continue;
			address _prevOwner = _index == 0 ? address(0x1) : _owners[_index - 1];
			bool _success = _removeOwner(_prevOwner, _owner, 1);
			assert(_success);
		}
		uint256 _threshold = G.min(_candidateCount, SIGNING_THRESHOLD);
		bool _success = _changeThreshold(_threshold);
		assert(_success);
		synced = true;
	}

	function _addOwnerWithThreshold(address _owner, uint256 _threshold) internal returns (bool _success)
	{
		bytes memory _data = abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", _owner, _threshold);
		return Safe(safe).execTransactionFromModule(safe, 0, _data, Enum.Operation.Call);
	}

	function _removeOwner(address _prevOwner, address _owner, uint256 _threshold) internal returns (bool _success)
	{
		bytes memory _data = abi.encodeWithSignature("removeOwner(address,address,uint256)", _prevOwner, _owner, _threshold);
		return Safe(safe).execTransactionFromModule(safe, 0, _data, Enum.Operation.Call);
	}

	function _changeThreshold(uint256 _threshold) internal returns (bool _success)
	{
		bytes memory _data = abi.encodeWithSignature("changeThreshold(uint256)", _threshold);
		return Safe(safe).execTransactionFromModule(safe, 0, _data, Enum.Operation.Call);
	}
}
