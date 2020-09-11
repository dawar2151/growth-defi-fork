// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Factory
{
	function newBPool() external returns (Pool _pool);
}

interface Pool is IERC20
{
/*
	// function getColor() external view returns (bytes32 _color);
	// function increaseApproval(address _spender, uint256 _amount) external returns (bool _success);
	// function decreaseApproval(address _spender, uint256 _amount) external returns (bool _success);

	function calcSpotPrice(uint256 _tokenBalanceIn, uint256 _tokenWeightIn, uint256 _tokenBalanceOut, uint256 _tokenWeightOut, uint256 _swapFee) external pure returns (uint256 _spotPrice);
	function calcOutGivenIn(uint256 _tokenBalanceIn, uint256 _tokenWeightIn, uint256 _tokenBalanceOut, uint256 _tokenWeightOut, uint256 _tokenAmountIn, uint256 _swapFee) external pure returns (uint256 _tokenAmountOut);
	function calcInGivenOut(uint256 _tokenBalanceIn, uint256 _tokenWeightIn, uint256 _tokenBalanceOut, uint256 _tokenWeightOut, uint256 _tokenAmountOut, uint256 _swapFee) external pure returns (uint256 _tokenAmountIn);
	function calcPoolOutGivenSingleIn(uint256 _tokenBalanceIn, uint256 _tokenWeightIn, uint256 _poolSupply, uint256 _totalWeight, uint256 _tokenAmountIn, uint256 _swapFee) external pure returns (uint256 _poolAmountOut);
	function calcSingleInGivenPoolOut(uint256 _tokenBalanceIn, uint256 _tokenWeightIn, uint256 _poolSupply, uint256 _totalWeight, uint256 _poolAmountOut, uint256 _swapFee) external pure returns (uint256 _tokenAmountIn);
	function calcSingleOutGivenPoolIn(uint256 _tokenBalanceOut, uint256 _tokenWeightOut, uint256 _poolSupply, uint256 _totalWeight, uint256 _poolAmountIn, uint256 _swapFee) external pure returns (uint256 _tokenAmountOut);
	function calcPoolInGivenSingleOut(uint256 _tokenBalanceOut, uint256 _tokenWeightOut, uint256 _poolSupply, uint256 _totalWeight, uint256 _tokenAmountOut, uint256 _swapFee) external pure returns (uint256 _poolAmountIn);

	function isPublicSwap() external view returns (bool _is);
	function isFinalized() external view returns (bool _is);
	function isBound(address _token) external view returns (bool _is);
	function getNumTokens() external view returns (uint256 _count);
	function getCurrentTokens() external view returns (address[] memory _tokens);
	function getFinalTokens() external view returns (address[] memory _tokens);
	function getDenormalizedWeight(address _token) external view returns (uint256 _weight);
	function getTotalDenormalizedWeight() external view returns (uint256 _weight);
	function getNormalizedWeight(address _token) external view returns (uint256 _weight);
*/
	function getBalance(address _token) external view returns (uint256 _balance);
/*
	function getSwapFee() external view returns (uint256 _swapFee);
	function getController() external view returns (address _manager);
*/
	function setSwapFee(uint256 _swapFee) external;
/*
	function setController(address _manager) external;
	function setPublicSwap(bool _public) external;
*/
	function finalize() external;
	function bind(address _token, uint256 _balance, uint256 _denorm) external;
/*
	function rebind(address _token, uint256 _balance, uint256 _denorm) external;
	function unbind(address _token) external;
	function gulp(address _token) external;
	function getSpotPrice(address _tokenIn, address _tokenOut) external view returns (uint256 _spotPrice);
	function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 _spotPrice);
	function joinPool(uint256 _poolAmountOut, uint256[] calldata _maxAmountsIn) external;
	function exitPool(uint256 _poolAmountIn, uint256[] calldata _minAmountsOut) external;
	function swapExactAmountIn(address _tokenIn, uint256 _tokenAmountIn, address _tokenOut, uint256 _minAmountOut, uint256 _maxPrice) external returns (uint256 _tokenAmountOut, uint256 _spotPriceAfter);
	function swapExactAmountOut(address _tokenIn, uint256 _maxAmountIn, address _tokenOut, uint256 _tokenAmountOut, uint256 _maxPrice) external returns (uint256 _tokenAmountIn, uint256 _spotPriceAfter);
*/
	function joinswapExternAmountIn(address _tokenIn, uint256 _tokenAmountIn, uint256 _minPoolAmountOut) external returns (uint256 _poolAmountOut);
/*
	function joinswapPoolAmountOut(address _tokenIn, uint256 _poolAmountOut, uint256 _maxAmountIn) external returns (uint256 _tokenAmountIn);
	function exitswapPoolAmountIn(address _tokenOut, uint256 _poolAmountIn, uint256 _minAmountOut) external returns (uint256 _tokenAmountOut);
*/
	function exitswapExternAmountOut(address _tokenOut, uint256 _tokenAmountOut, uint256 _maxPoolAmountIn) external returns (uint256 _poolAmountIn);
}
