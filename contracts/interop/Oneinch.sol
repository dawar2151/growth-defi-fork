// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Oneinch
{
	function getExpectedReturn(IERC20 _fromToken, IERC20 _destToken, uint256 _amount, uint256 _parts, uint256 _flags) external view returns (uint256 _returnAmount, uint256[] memory _distribution);
	function swap(IERC20 _fromToken, IERC20 _destToken, uint256 _amount, uint256 _minReturn, uint256[] memory _distribution, uint256 _flags) external payable returns (uint256 _returnAmount);
}
