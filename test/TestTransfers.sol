// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Assert } from "truffle/Assert.sol";

import { Addresses } from "../contracts/Addresses.sol";
import { Transfers } from "../contracts/gcDAI.sol";
import { Router02 } from "../contracts/interop/UniswapV2.sol";

contract TestTransfers is Transfers
{
	uint256 public initialBalance = 5 ether;

	receive() external payable {}

	function _mintTokenBalance(address _token, uint256 _outputAmount) internal
	{
		Assert.equal(_getBalance(_token), 0, "balance must be 0");
		Router02 _router = Router02(Addresses.UniswapV2_ROUTER02);
		address[] memory _path = new address[](2);
		_path[0] = _router.WETH();
		_path[1] = _token;
		_router.swapETHForExactTokens{value: address(this).balance}(_outputAmount, _path, address(this), uint256(-1));
		Assert.equal(_getBalance(_token), _outputAmount, "token output amounts must match");
	}

	function _returnFullTokenBalance(address _token) internal
	{
		_pushFunds(_token, msg.sender, _getBalance(_token));
		Assert.equal(_getBalance(_token), 0, "balance must be 0");
	}

	function test01() public
	{
		_returnFullTokenBalance(Addresses.DAI);
		_returnFullTokenBalance(Addresses.USDC);
		Assert.equal(_getBalance(Addresses.USDC), 0e6, "USDC balance must be 0e6");
		_convertFundsUSDCToDAI(0e6);
		Assert.equal(_getBalance(Addresses.USDC), 0e6, "USDC balance must be 0e6");
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");
	}

	function test02() public
	{
		_returnFullTokenBalance(Addresses.DAI);
		_returnFullTokenBalance(Addresses.USDC);
		Assert.equal(_getBalance(Addresses.USDC), 0e6, "USDC balance must be 0e6");
		_mintTokenBalance(Addresses.USDC, 100e6);
		Assert.equal(_getBalance(Addresses.USDC), 100e6, "USDC balance must be 100e6");
		_convertFundsUSDCToDAI(80e6);
		Assert.equal(_getBalance(Addresses.USDC), 20e6, "USDC balance must be 20e6");
		Assert.isAbove(_getBalance(Addresses.DAI), 0e18, "DAI balance must be above 0e18");
	}

	function test03() public
	{
		_returnFullTokenBalance(Addresses.DAI);
		_returnFullTokenBalance(Addresses.USDC);
		Assert.equal(_getBalance(Addresses.USDC), 0e6, "USDC balance must be 0e6");
		_mintTokenBalance(Addresses.USDC, 333e6);
		Assert.equal(_getBalance(Addresses.USDC), 333e6, "USDC balance must be 333e6");
		_convertFundsUSDCToDAI(333e6);
		Assert.equal(_getBalance(Addresses.USDC), 0e6, "USDC balance must be 0e6");
		Assert.isAbove(_getBalance(Addresses.DAI), 0e18, "DAI balance must be above 0e18");
	}

	function test04() public
	{
		_returnFullTokenBalance(Addresses.DAI);
		_returnFullTokenBalance(Addresses.COMP);
		Assert.equal(_getBalance(Addresses.COMP), 0e18, "COMP balance must be 0e18");
		_convertFundsCOMPToDAI(0e18);
		Assert.equal(_getBalance(Addresses.COMP), 0e18, "COMP balance must be 0e18");
		Assert.equal(_getBalance(Addresses.DAI), 0e18, "DAI balance must be 0e18");
	}

	function test05() public
	{
		_returnFullTokenBalance(Addresses.DAI);
		_returnFullTokenBalance(Addresses.COMP);
		Assert.equal(_getBalance(Addresses.COMP), 0e18, "COMP balance must be 0e18");
		_mintTokenBalance(Addresses.COMP, 2e18);
		Assert.equal(_getBalance(Addresses.COMP), 2e18, "COMP balance must be 2e18");
		_convertFundsCOMPToDAI(1e18);
		Assert.equal(_getBalance(Addresses.COMP), 1e18, "COMP balance must be 1e18");
		Assert.isAbove(_getBalance(Addresses.DAI), 0e18, "DAI balance must be above 0e18");
	}

	function test06() public
	{
		_returnFullTokenBalance(Addresses.DAI);
		_returnFullTokenBalance(Addresses.COMP);
		Assert.equal(_getBalance(Addresses.COMP), 0e18, "COMP balance must be 0e18");
		_mintTokenBalance(Addresses.COMP, 3e18);
		Assert.equal(_getBalance(Addresses.COMP), 3e18, "COMP balance must be 3e18");
		_convertFundsCOMPToDAI(3e18);
		Assert.equal(_getBalance(Addresses.COMP), 0e18, "COMP balance must be 0e18");
		Assert.isAbove(_getBalance(Addresses.DAI), 0e18, "DAI balance must be above 0e18");
	}
}
