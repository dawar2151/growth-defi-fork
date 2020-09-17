// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { GFormulae } from "./GFormulae.sol";

contract GCFormulae is GFormulae
{
	function _calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) internal pure returns (uint256 _cost)
	{
		return _underlyingCost.mul(1e18).div(_exchangeRate);
	}

	function _calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) internal pure returns (uint256 _underlyingCost)
	{
		return _cost.mul(_exchangeRate).div(1e18);
	}
}
