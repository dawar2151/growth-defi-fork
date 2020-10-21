// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { WETH } from "../interop/WrappedEther.sol";

import { $ } from "../network/$.sol";

library Wrapping
{
	function _wrap(uint256 _amount) internal returns (bool _success)
	{
		try WETH($.WETH).deposit{value: _amount}() {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	function _unwrap(uint256 _amount) internal returns (bool _success)
	{
		try WETH($.WETH).withdraw(_amount) {
			return true;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}

	function _safeWrap(uint256 _amount) internal
	{
		require(_wrap(_amount), "wrap failed");
	}

	function _safeUnwrap(uint256 _amount) internal
	{
		require(_unwrap(_amount), "unwrap failed");
	}
}
