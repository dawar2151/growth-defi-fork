// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

interface GExchange
{
	function calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) external view returns (uint256 _outputAmount);
	function calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) external view returns (uint256 _inputAmount);
	function convertFunds(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) external returns (uint256 _outputAmount);
}
