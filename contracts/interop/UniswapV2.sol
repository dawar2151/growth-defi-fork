// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
/*
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface FactoryV2
{
	function createPair(address _tokenA, address _tokenB) external returns (address _pair);
	function getPair(address _tokenA, address _tokenB) external view returns (address _pair);
	function allPairs(uint256 _index) external view returns (address _pair);
	function allPairsLength() external view returns (uint256 _count);
	function feeTo() external view returns (address _feeTo);
	function feeToSetter() external view returns (address _feeToSetter);
	// function setFeeTo(address _feeTo) external;
	// function setFeeToSetter(address _feeToSetter) external;

	event PairCreated(address indexed _token0, address indexed _token1, address _pair, uint256 _count);
}

interface PoolToken is IERC20
{
	function DOMAIN_SEPARATOR() external view returns (bytes32 _DOMAIN_SEPARATOR);
	function PERMIT_TYPEHASH() external pure returns (bytes32 _PERMIT_TYPEHASH);
	function nonces(address _owner) external view returns (uint256 _nonces);
	function permit(address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;
}

interface Pair is PoolToken
{
	// function initialize(address _token0, address _token1) external;
	function MINIMUM_LIQUIDITY() external pure returns (uint256 _MINIMUM_LIQUIDITY);
	function factory() external view returns (address _factory);
	function token0() external view returns (address _token0);
	function token1() external view returns (address _token1);
	function price0CumulativeLast() external view returns (uint256 _price0CumulativeLast);
	function price1CumulativeLast() external view returns (uint256 _price1CumulativeLast);
	function kLast() external view returns (uint256 _kLast);
	function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
	function mint(address _to) external returns (uint256 _liquidity);
	function burn(address _to) external returns (uint256 _amount0, uint256 _amount1);
	function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes calldata _data) external;
	function skim(address _to) external;
	function sync() external;

	event Mint(address indexed _sender, uint256 _amount0, uint256 _amount1);
	event Burn(address indexed _sender, uint256 _amount0, uint256 _amount1, address indexed _to);
	event Swap(address indexed _sender, uint256 _amount0In, uint256 _amount1In, uint256 _amount0Out, uint256 _amount1Out, address indexed _to);
	event Sync(uint112 _reserve0, uint112 _reserve1);
}
*/
interface Router01
{
/*
	function factory() external pure returns (address _factory);
*/
	function WETH() external pure returns (address _token);
/*
	function addLiquidity(address _tokenA, address _tokenB, uint256 _amountADesired, uint256 _amountBDesired, uint256 _amountAMin, uint256 _amountBMin, address _to, uint256 _deadline) external returns (uint256 _amountA, uint256 _amountB, uint256 _liquidity);
	function addLiquidityETH(address _token, uint256 _amountTokenDesired, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline) external payable returns (uint256 _amountToken, uint256 _amountETH, uint256 _liquidity);
	function removeLiquidity(address _tokenA, address _tokenB, uint256 _liquidity, uint256 _amountAMin, uint256 _amountBMin, address _to, uint256 _deadline) external returns (uint256 _amountA, uint256 _amountB);
	function removeLiquidityETH(address token, uint256 _liquidity, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline) external returns (uint256 _amountToken, uint256 _amountETH);
	function removeLiquidityWithPermit(address _tokenA, address _tokenB, uint256 _liquidity, uint256 _amountAMin, uint256 _amountBMin, address _to, uint256 _deadline, bool _approveMax, uint8 _v, bytes32 _r, bytes32 _s) external returns (uint256 _amountA, uint256 _amountB);
	function removeLiquidityETHWithPermit(address _token, uint256 _liquidity, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline, bool _approveMax, uint8 _v, bytes32 _r, bytes32 _s) external returns (uint256 _amountToken, uint256 _amountETH);
*/
	function swapExactTokensForTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
/*
	function swapTokensForExactTokens(uint256 _amountOut, uint256 _amountInMax, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
	function swapExactETHForTokens(uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external payable returns (uint256[] memory _amounts);
	function swapTokensForExactETH(uint256 _amountOut, uint256 _amountInMax, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
	function swapExactTokensForETH(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
*/
	function swapETHForExactTokens(uint256 _amountOut, address[] calldata _path, address _to, uint256 _deadline) external payable returns (uint256[] memory _amounts);
/*
	function quote(uint256 _amountA, uint256 _reserveA, uint256 _reserveB) external pure returns (uint256 _amountB);
	function getAmountOut(uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut) external pure returns (uint256 _amountOut);
	function getAmountIn(uint256 _amountOut, uint256 _reserveIn, uint256 _reserveOut) external pure returns (uint256 _amountIn);
*/
	function getAmountsOut(uint256 _amountIn, address[] calldata _path) external view returns (uint[] memory _amounts);
	function getAmountsIn(uint256 _amountOut, address[] calldata _path) external view returns (uint[] memory _amounts);
}

interface Router02 is Router01
{
/*
	function removeLiquidityETHSupportingFeeOnTransferTokens(address _token, uint256 _liquidity, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline) external returns (uint256 _amountETH);
	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address _token, uint256 _liquidity, uint256 _amountTokenMin, uint256 _amountETHMin, address _to, uint256 _deadline, bool _approveMax, uint8 _v, bytes32 _r, bytes32 _s) external returns (uint _amountETH);
	function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external;
	function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external payable;
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external;
*/
}
/*
interface FlashSwapReceiver
{
	function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external;
}
*/
