// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { GFormulae } from "./GFormulae.sol";
import { GCFormulae } from "./GCFormulae.sol";
import { GCTokenType1 } from "./GCTokenType1.sol";
import { GCTokenType2 } from "./GCTokenType2.sol";
import { G } from "./G.sol";

import { $ } from "./network/$.sol";

/**
 * @notice Definition of gcDAI. As a gcToken Type 1, it uses cDAI as reserve
 * and employs leverage to maximize returns.
 */
contract gcDAI is GCTokenType1
{
	constructor ()
		GCTokenType1("growth cDAI", "gcDAI", 8, $.GRO, $.cDAI, $.COMP) public
	{
	}
}

/**
 * @notice Definition of gcUSDC. As a gcToken Type 1, it uses cUSDC as reserve
 * and employs leverage to maximize returns.
 */
contract gcUSDC is GCTokenType1
{
	constructor ()
		GCTokenType1("growth cUSDC", "gcUSDC", 8, $.GRO, $.cUSDC, $.COMP) public
	{
	}
}

/**
 * @notice Definition of gcUSDT. As a gcToken Type 1, it uses cUSDT as reserve
 * and employs leverage to maximize returns.
 */
contract gcUSDT is GCTokenType1
{
	constructor ()
		GCTokenType1("growth cUSDT", "gcUSDT", 8, $.GRO, $.cUSDT, $.COMP) public
	{
	}
}

/**
 * @notice Definition of gcETH. As a gcToken Type 2, it uses cETH as reserve
 * which serves as collateral for minting gcDAI.
 */
contract gcETH is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cETH", "gcETH", 8, $.GRO, $.cETH, $.COMP, _growthToken) public
	{
	}

	function depositETH() public payable {
		address _from = msg.sender;
		uint256 _underlyingCost = msg.value;
		require(_underlyingCost > 0, "underlying cost must be greater than 0");
		uint256 _cost = GCFormulae._calcCostFromUnderlyingCost(_underlyingCost, exchangeRate());
		(uint256 _netShares, uint256 _feeShares) = GFormulae._calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "shares must be greater than 0");
		G.safeWrap(_underlyingCost);
		G.safeLend(reserveToken, _underlyingCost);
		require(_prepareDeposit(_cost), "not available at the moment");
		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
	}

	function withdrawETH(uint256 _grossShares) public
	{
		address payable _from = msg.sender;
		require(_grossShares > 0, "shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = GFormulae._calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		uint256 _underlyingCost = GCFormulae._calcUnderlyingCostFromCost(_cost, exchangeRate());
		require(_underlyingCost > 0, "underlying cost must be greater than 0");
		require(_prepareWithdrawal(_cost), "not available at the moment");
		_underlyingCost = G.min(_underlyingCost, G.getLendAmount(reserveToken));
		G.safeRedeem(reserveToken, _underlyingCost);
		G.safeUnwrap(_underlyingCost);
		_from.transfer(_underlyingCost);
		_burn(_from, _grossShares);
		_mint(address(this), _feeShares.div(2));
		lpm.gulpPoolAssets();
	}

	receive() external payable {}
}

/**
 * @notice Definition of gcWBTC. As a gcToken Type 2, it uses cWBTC as reserve
 * which serves as collateral for minting gcDAI.
 */
contract gcWBTC is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cWBTC", "gcWBTC", 8, $.GRO, $.cWBTC, $.COMP, _growthToken) public
	{
	}
}

/**
 * @notice Definition of gcBAT. As a gcToken Type 2, it uses cBAT as reserve
 * which serves as collateral for minting gcDAI.
 */
contract gcBAT is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cBAT", "gcBAT", 8, $.GRO, $.cBAT, $.COMP, _growthToken) public
	{
	}
}

/**
 * @notice Definition of gcZRX. As a gcToken Type 2, it uses cZRX as reserve
 * which serves as collateral for minting gcDAI.
 */
contract gcZRX is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cZRX", "gcZRX", 8, $.GRO, $.cZRX, $.COMP, _growthToken) public
	{
	}
}

/**
 * @notice Definition of gcUNI. As a gcToken Type 2, it uses cUNI as reserve
 * which serves as collateral for minting gcDAI.
 */
contract gcUNI is GCTokenType2
{
	constructor (address _growthToken)
		GCTokenType2("growth cUNI", "gcUNI", 8, $.GRO, $.cUNI, $.COMP, _growthToken) public
	{
	}
}
