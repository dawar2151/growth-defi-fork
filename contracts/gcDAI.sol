// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { Addresses } from "./Addresses.sol";
import { GToken, GCToken } from "./GToken.sol";

import { Factory, Pool } from "./interop/Balancer.sol";
import { Comptroller, PriceOracle, CToken } from "./interop/Compound.sol";
import { Oneinch } from "./interop/Oneinch.sol";

contract GFormulae
{
	using SafeMath for uint256;

	function _calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) internal pure returns (uint256 _netShares, uint256 _feeShares)
	{
		uint256 _grossShares = _totalReserve == 0 ? _cost : _cost.mul(_totalSupply).div(_totalReserve);
		_netShares = _grossShares.mul(1e18).div(_depositFee.add(1e18));
		_feeShares = _grossShares.sub(_netShares);
		return (_netShares, _feeShares);
	}

	function _calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) internal pure returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _grossShares = _netShares.mul(_depositFee.add(1e18)).div(1e18);
		_cost = _totalSupply == 0 ? _grossShares : _grossShares.mul(_totalReserve).div(_totalSupply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}

	function _calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) internal pure returns (uint256 _grossShares, uint256 _feeShares)
	{
		uint256 _netShares = _totalReserve == 0 ? _cost : _cost.mul(_totalSupply).div(_totalReserve);
		_grossShares = _netShares.mul(1e18).div(_withdrawalFee.sub(1e18));
		_feeShares = _grossShares.sub(_netShares);
		return (_grossShares, _feeShares);
	}

	function _calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) internal pure returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _netShares = _grossShares.mul(_withdrawalFee.sub(1e18)).div(1e18);
		_cost = _totalSupply == 0 ? _netShares : _netShares.mul(_totalReserve).div(_totalSupply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}
}

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

contract BalancerLiquidityPoolAbstraction
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 constant TOKEN0_WEIGHT = 50e16; // 50%
	uint256 constant TOKEN1_WEIGHT = 50e16; // 50%
	uint256 constant SWAP_FEE = 10e16; // 10%

	function _createPool(address _token0, uint256 _amount0, address _token1, uint256 _amount1) internal returns (address _pool)
	{
		_pool = Factory(Addresses.Balancer_FACTORY).newBPool();
		IERC20(_token0).safeApprove(_pool, _amount0);
		Pool(_pool).bind(_token0, _amount0, TOKEN0_WEIGHT);
		IERC20(_token1).safeApprove(_pool, _amount1);
		Pool(_pool).bind(_token1, _amount1, TOKEN1_WEIGHT);
		Pool(_pool).setSwapFee(SWAP_FEE);
		Pool(_pool).finalize();
		return _pool;
	}

	function _getPoolBalances(address _pool, address _token0, address _token1) internal view returns (uint256 _amount0, uint256 _amount1)
	{
		uint256 _totalSupply = Pool(_pool).totalSupply();
		uint256 _ownedBalance = Pool(_pool).balanceOf(address(this));
		uint256 _balance0 = Pool(_pool).getBalance(_token0);
		uint256 _balance1 = Pool(_pool).getBalance(_token1);
		_amount0 = _balance0.mul(_ownedBalance).div(_totalSupply);
		_amount1 = _balance1.mul(_ownedBalance).div(_totalSupply);
		return (_amount0, _amount1);
	}

	function _joinPool(address _pool, address _token0, uint256 _amount0, address _token1, uint256 _amount1) internal
	{
		if (_amount0 > 0) {
			IERC20(_token0).safeApprove(_pool, _amount0);
			Pool(_pool).joinswapExternAmountIn(_token0, _amount0, 0);
		}
		if (_amount1 > 0) {
			IERC20(_token1).safeApprove(_pool, _amount1);
			Pool(_pool).joinswapExternAmountIn(_token1, _amount1, 0);
		}
	}

	function _exitPool(address _pool, address _token0, uint256 _amount0, address _token1, uint256 _amount1) internal
	{
		if (_amount0 > 0) {
			Pool(_pool).exitswapExternAmountOut(_token0, _amount0, uint256(-1));
		}
		if (_amount1 > 0) {
			Pool(_pool).exitswapExternAmountOut(_token1, _amount1, uint256(-1));
		}
	}
}

contract Transfers
{
	using SafeERC20 for IERC20;

	function _getBalance(address _token) internal view returns (uint256 _balance)
	{
		return IERC20(_token).balanceOf(address(this));
	}

	function _pullFunds(address _token, address _from, uint256 _amount) internal
	{
		IERC20(_token).safeTransferFrom(_from, address(this), _amount);
	}

	function _pushFunds(address _token, address _to, uint256 _amount) internal
	{
		IERC20(_token).safeTransfer(_to, _amount);
	}
}

contract GLiquidityPoolManager is Transfers, BalancerLiquidityPoolAbstraction
{
	enum State { Created, Allocated, Migrating, Migrated }

	uint256 constant BURNING_RATE = 5e15; // 0.5%
	uint256 constant BURNING_INTERVAL = 7 days;
	uint256 constant MIGRATION_INTERVAL = 7 days;

	address public immutable stakeToken;
	address public immutable sharesToken;

	State public state = State.Created;
	address public liquidityPool = address(0);

	uint256 public burningRate = BURNING_RATE;
	uint256 public lastBurningTime = 0;

	address public migrationRecipient = address(0);
	uint256 public migrationUnlockTime = uint256(-1);

	constructor (address _stakeToken, address _sharesToken) internal
	{
		stakeToken = _stakeToken;
		sharesToken = _sharesToken;
	}

	function _hasPool() internal view returns (bool _hasMigrated)
	{
		return state == State.Allocated || state == State.Migrating;
	}

	function _gulpPoolAssets() internal
	{
		if (_hasPool()) {
			_joinPool(liquidityPool, stakeToken, _getBalance(stakeToken), sharesToken, _getBalance(sharesToken));
		}
	}

	function _setBurningRate(uint256 _burningRate) internal
	{
		require(_burningRate <= 1e18, "invalid rate");
		burningRate = _burningRate;
	}

	function _burnPoolPortion() internal returns (uint256 _stakeAmount, uint256 _sharesAmount)
	{
		require(_hasPool(), "pool not available");
		require(now > lastBurningTime + BURNING_INTERVAL, "must wait lock interval");
		(_stakeAmount, _sharesAmount) = _getPoolBalances(liquidityPool, stakeToken, sharesToken);
		_stakeAmount = _stakeAmount.mul(burningRate).div(1e18);
		_sharesAmount = _sharesAmount.mul(burningRate).div(1e18);
		_exitPool(liquidityPool, stakeToken, _stakeAmount, sharesToken, _sharesAmount);
		lastBurningTime = now;
	}

	function _allocatePool(uint256 _stakeAmount, uint256 _sharesAmount) internal
	{
		require(state == State.Created, "pool cannot be allocated");
		liquidityPool = _createPool(stakeToken, _stakeAmount, sharesToken, _sharesAmount);
		state = State.Allocated;
	}

	function _initiatePoolMigration(address _migrationRecipient) internal
	{
		require(state == State.Allocated, "pool not allocated");
		migrationRecipient = _migrationRecipient;
		migrationUnlockTime = now + MIGRATION_INTERVAL;
		state = State.Migrating;
	}

	function _cancelPoolMigration() internal
	{
		require(state == State.Migrating, "migration not initiated");
		migrationRecipient = address(0);
		migrationUnlockTime = uint256(-1);
		state = State.Allocated;
	}

	function _completePoolMigration() internal returns (address _migrationRecipient, uint256 _stakeAmount, uint256 _sharesAmount)
	{
		require(state == State.Migrating, "migration not initiated");
		require(now >= migrationUnlockTime, "must wait lock interval");
		(_stakeAmount, _sharesAmount) = _getPoolBalances(liquidityPool, stakeToken, sharesToken);
		_exitPool(liquidityPool, stakeToken, _stakeAmount, sharesToken, _sharesAmount);
		state = State.Migrated;
		return (migrationRecipient, _stakeAmount, _sharesAmount);
	}
}

contract GTokenBase is ERC20, Ownable, ReentrancyGuard, GToken, GFormulae, GLiquidityPoolManager
{
	uint256 constant DEPOSIT_FEE = 1e16; // 1%
	uint256 constant WITHDRAWAL_FEE = 1e16; // 1%

	address public immutable reserveToken;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakeToken, address _reserveToken)
		ERC20(_name, _symbol) GLiquidityPoolManager(_stakeToken, address(this)) public
	{
		_setupDecimals(_decimals);
		reserveToken = _reserveToken;
	}

	function calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) public pure override returns (uint256 _netShares, uint256 _feeShares)
	{
		return _calcDepositSharesFromCost(_cost, _totalReserve, _totalSupply, _depositFee);
	}

	function calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		return _calcDepositCostFromShares(_netShares, _totalReserve, _totalSupply, _depositFee);
	}

	function calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) public pure override returns (uint256 _grossShares, uint256 _feeShares)
	{
		return _calcWithdrawalSharesFromCost(_cost, _totalReserve, _totalSupply, _withdrawalFee);
	}

	function calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		return _calcWithdrawalCostFromShares(_grossShares, _totalReserve, _totalSupply, _withdrawalFee);
	}

	function depositFee() public view returns (uint256 _depositFee) {
		return _hasPool() ? DEPOSIT_FEE : 0;
	}

	function withdrawalFee() public view returns (uint256 _withdrawalFee) {
		return _hasPool() ? WITHDRAWAL_FEE : 0;
	}

	function totalReserve() public override returns (uint256 _totalReserve)
	{
		return _getBalance(reserveToken);
	}

	function deposit(uint256 _cost) external override nonReentrant
	{
		address _from = msg.sender;
		require(_cost > 0, "deposit must be greater than 0");
		(uint256 _netShares, uint256 _feeShares) = calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		_pullFunds(reserveToken, _from, _cost);
		_mint(_from, _netShares);
		_mint(sharesToken, _feeShares.div(2));
		_gulpPoolAssets();
	}

	function withdraw(uint256 _grossShares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "withdraw must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		_pushFunds(reserveToken, _from, _cost);
		_burn(_from, _grossShares);
		_mint(sharesToken, _feeShares.div(2));
		_gulpPoolAssets();
	}

	function allocateLiquidityPool(uint256 _stakeAmount, uint256 _sharesAmount) public override onlyOwner nonReentrant
	{
		address _from = msg.sender;
		_pullFunds(stakeToken, _from, _stakeAmount);
		_pullFunds(sharesToken, _from, _sharesAmount);
		_allocatePool(_stakeAmount, _sharesAmount);
	}

	function setLiquidityPoolBurningRate(uint256 _burningRate) public override onlyOwner nonReentrant
	{
		_setBurningRate(_burningRate);
	}

	function burnLiquidityPoolPortion() public override onlyOwner nonReentrant
	{
		(uint256 _stakeAmount, uint256 _sharesAmount) = _burnPoolPortion();
		_pushFunds(stakeToken, address(0), _stakeAmount);
		_burn(sharesToken, _sharesAmount);
		emit BurnLiquidityPoolPortion(_stakeAmount, _sharesAmount);
	}

	function initiateLiquidityPoolMigration(address _migrationRecipient) public override onlyOwner nonReentrant
	{
		_initiatePoolMigration(_migrationRecipient);
		emit InitiateLiquidityPoolMigration();
	}

	function cancelLiquidityPoolMigration() public override onlyOwner nonReentrant
	{
		_cancelPoolMigration();
		emit CancelLiquidityPoolMigration();
	}

	function completeLiquidityPoolMigration() public override onlyOwner nonReentrant
	{
		(address _to, uint256 _stakeAmount, uint256 _sharesAmount) = _completePoolMigration();
		_pushFunds(stakeToken, _to, _stakeAmount);
		_pushFunds(sharesToken, _to, _sharesAmount);
		emit CompleteLiquidityPoolMigration();
	}

	event BurnLiquidityPoolPortion(uint256 _stakeAmount, uint256 _sharesAmount);
	event InitiateLiquidityPoolMigration();
	event CancelLiquidityPoolMigration();
	event CompleteLiquidityPoolMigration();
}

contract CompoundLendingMarketAbstraction
{
	using SafeERC20 for IERC20;

	function _getUnderlyingToken(address _ctoken) internal view returns (address _token)
	{
		return CToken(_ctoken).underlying();
	}

	function _getExchangeRate(address _ctoken, address /* _token */) internal returns (uint256 _exchangeRate)
	{
		return CToken(_ctoken).exchangeRateCurrent();
	}

	function _lend(address _ctoken, uint256 /* _camount */, address _token, uint256 _amount) internal
	{
		IERC20(_token).safeApprove(_ctoken, _amount);
		uint256 _result = CToken(_ctoken).mint(_amount);
		require(_result == 0, "lend failure");
	}

	function _redeem(address _ctoken, uint256 /* _camount */, address /* _token */, uint256 _amount) internal
	{
		uint256 _result = CToken(_ctoken).redeemUnderlying(_amount);
		require(_result == 0, "redeem failure");
	}
/*
	function _borrowAlternative(uint256 _amount) internal
	{
		uint256 _result = btoken.borrow(_amount);
		require(_result == 0, "borrow failure");
	}

	function _repayAlternative(uint256 _amount) internal
	{
		utoken.safeApprove(address(btoken), _amount);
		uint256 _result = btoken.repayBorrow(_amount);
		require(_result == 0, "repay failure");
	}
*/
}

contract GCTokenBase is GTokenBase, GCToken, GCFormulae, CompoundLendingMarketAbstraction
{
	address public immutable underlyingToken;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakeToken, address _reserveToken)
		GTokenBase(_name, _symbol, _decimals, _stakeToken, _reserveToken) public
	{
		underlyingToken = _getUnderlyingToken(_reserveToken);
	}

	function calcCostFromUnderlyingCost(uint256 _underlyingCost, uint256 _exchangeRate) public pure override returns (uint256 _cost)
	{
		return _calcCostFromUnderlyingCost(_underlyingCost, _exchangeRate);
	}

	function calcUnderlyingCostFromCost(uint256 _cost, uint256 _exchangeRate) public pure override returns (uint256 _underlyingCost)
	{
		return _calcUnderlyingCostFromCost(_cost, _exchangeRate);
	}

	function totalReserveUnderlying() public override returns (uint256 _totalReserveUnderlying)
	{
		return _calcUnderlyingCostFromCost(totalReserve(), _getExchangeRate(reserveToken, underlyingToken));
	}

	function depositUnderlying(uint256 _underlyingCost) external override nonReentrant
	{
		address _from = msg.sender;
		require(_underlyingCost > 0, "deposit must be greater than 0");
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _getExchangeRate(reserveToken, underlyingToken));
		(uint256 _netShares, uint256 _feeShares) = calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		_pullFunds(underlyingToken, _from, _underlyingCost);
		_mint(_from, _netShares);
		_mint(sharesToken, _feeShares.div(2));
		_lend(reserveToken, _cost, underlyingToken, _underlyingCost);
		_gulpPoolAssets();
	}

	function withdrawUnderlying(uint256 _grossShares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "withdraw must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		uint256 _underlyingCost = _calcUnderlyingCostFromCost(_cost, _getExchangeRate(reserveToken, underlyingToken));
		_redeem(reserveToken, _cost, underlyingToken, _underlyingCost);
		_pushFunds(underlyingToken, _from, _underlyingCost);
		_burn(_from, _grossShares);
		_mint(sharesToken, _feeShares.div(2));
		_gulpPoolAssets();
	}
}

contract gcDAI is GCTokenBase
{
/*
	IERC20 private utoken = CToken(USDC);
	CToken private btoken = CToken(cUSDC);

	bool public borrowProfitable = false;
*/
	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 18, Addresses.GRO, Addresses.cDAI) public
	{
/*
		_initializeOptimalReturns();
*/
	}
/*
	function totalReserve() public override returns (uint256 _reserve)
	{
		return _calcActualReserve();
	}

	function _initializeOptimalReturns() internal
	{
		Comptroller comptroller = Comptroller(Compound_Comptroller);
		address[] memory ctokens = new address[](1);
		ctokens[0] = address(ctoken);
		uint256[] memory errors = comptroller.enterMarkets(ctokens);
		require(errors[0] == 0, "enterMarkets failed");
	}

	function _calcActualReserve() internal returns (uint256 _reserve)
	{
		uint256 _bonusCOMP = IERC20(COMP).balanceOf(address(this));
		uint256 _bonusDAI = _giveExchangeRate(IERC20(COMP), token, _bonusCOMP);
		uint256 _borrowedUSDC = btoken.borrowBalanceCurrent(address(this));
		uint256 _borrowedDAI = _takeExchangeRate(token, utoken, _borrowedUSDC);
		uint256 _balancecDAI = ctoken.balanceOf(address(this));
		uint256 _balanceDAI = calcUnderlyingFromCost(_balancecDAI, ctoken.exchangeRateCurrent());
		uint256 _depositDAI = _balanceDAI.add(_bonusDAI).sub(_borrowedDAI);
		uint256 _depositcDAI = calcCostFromUnderlying(_depositDAI, ctoken.exchangeRateCurrent());
		return _depositcDAI;
	}

	function _collectBonus() internal
	{
		uint256 _bonusCOMP = IERC20(COMP).balanceOf(address(this));
		uint256 _resultDAI = _convertBalance(IERC20(COMP), token, _bonusCOMP);
		_lendUnderlying(_resultDAI);
	}

	uint256 IDEAL_COLLATERIZATION_RATIO = 65e16; // 65%
	uint256 LIMIT_COLLATERIZATION_RATIO = 70e16; // 70%
	uint256 MAXIMAL_OPERATIONAL_AMOUNT = 1000e18; // $1,000

	function _adjustOptimalReturns() internal
	{
		_collectBonus();

		uint256 _balancecDAI = ctoken.balanceOf(address(this));
		uint256 _balanceDAI = calcUnderlyingFromCost(_balancecDAI, ctoken.exchangeRateCurrent());

		uint256 _idealBorrowedDAI = _balanceDAI.mul(IDEAL_COLLATERIZATION_RATIO).div(1e18);
		uint256 _limitBorrowedDAI = _balanceDAI.mul(LIMIT_COLLATERIZATION_RATIO).div(1e18);

		uint256 _borrowedUSDC = btoken.borrowBalanceCurrent(address(this));
		uint256 _borrowedDAI = _takeExchangeRate(token, utoken, _borrowedUSDC);

		bool _overCollateralized = _borrowedDAI < _idealBorrowedDAI;
		bool _underCollateralized = _borrowedDAI > _limitBorrowedDAI;

		if (borrowProfitable && _overCollateralized) {
			uint256 _complementDAI = _idealBorrowedDAI.sub(_borrowedDAI);
			if (_complementDAI > MAXIMAL_OPERATIONAL_AMOUNT) _complementDAI = MAXIMAL_OPERATIONAL_AMOUNT;
			uint256 _complementUSDC = _giveExchangeRate(token, utoken, _complementDAI);
			_borrowAlternative(_complementUSDC);
			uint256 _resultDAI = _convertBalance(utoken, token, _complementUSDC);
			_lendUnderlying(_resultDAI);
		}
		else
		if (!borrowProfitable || _underCollateralized) {
			uint256 _returnDAI = _borrowedDAI.sub(_idealBorrowedDAI);
			if (_returnDAI > MAXIMAL_OPERATIONAL_AMOUNT) _returnDAI = MAXIMAL_OPERATIONAL_AMOUNT;
			_redeemUnderlying(_returnDAI);
			uint256 _returnUSDC = _convertBalance(token, utoken, _returnDAI);
			_repayAlternative(_returnUSDC);
		}
	}

	/* DEX abstraction * /

	uint256 constant ONEINCH_PARTS = 100;

	function _giveExchangeRate(IERC20 _from, IERC20 _to, uint256 _amount) internal view returns (uint256 _retAmount)
	{
		if (_amount == 0) return 0;
		Oneinch oneinch = Oneinch(Oneinch_Exchange);
		(uint256 _returnAmount,) = oneinch.getExpectedReturn(_from, _to, _amount, ONEINCH_PARTS, 0);
		return _returnAmount;
	}

	function _takeExchangeRate(IERC20 _from, IERC20 _to, uint256 _amount) internal view returns (uint256 _returnAmount)
	{
		// TODO this is an approximation, assumex 5% spread
		uint256 _retAmount = _giveExchangeRate(_from, _to, _amount);
		return _retAmount.mul(105e16).div(100e16);
	}

	function _convertBalance(IERC20 _from, IERC20 _to, uint256 _amount) internal returns (uint256 _success)
	{
		if (_amount == 0) return 0;
		Oneinch oneinch = Oneinch(Oneinch_Exchange);
		(uint256 _returnAmount, uint256[] memory _distribution) = oneinch.getExpectedReturn(_from, _to, _amount, ONEINCH_PARTS, 0);
		_from.safeApprove(address(oneinch), _amount);
		oneinch.swap(_from, _to, _amount, _returnAmount, _distribution, 0);
		return _returnAmount;
	}
*/
}
