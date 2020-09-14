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

import { BFactory, BPool } from "./interop/Balancer.sol";
import { Comptroller, PriceOracle, CToken } from "./interop/Compound.sol";
import { Swap } from "./interop/Curve.sol";
import { Oneinch } from "./interop/Oneinch.sol";
import { Router02 } from "./interop/UniswapV2.sol";

contract GFormulae
{
	using SafeMath for uint256;

	function _calcDepositSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) internal pure returns (uint256 _netShares, uint256 _feeShares)
	{
		uint256 _grossShares = _totalReserve == _totalSupply ? _cost : _cost.mul(_totalSupply).div(_totalReserve);
		_netShares = _grossShares.mul(1e18).div(uint256(1e18).add(_depositFee));
		_feeShares = _grossShares.sub(_netShares);
		return (_netShares, _feeShares);
	}

	function _calcDepositCostFromShares(uint256 _netShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _depositFee) internal pure returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _grossShares = _netShares.mul(uint256(1e18).add(_depositFee)).div(1e18);
		_cost = _totalReserve == _totalSupply ? _grossShares : _grossShares.mul(_totalReserve).div(_totalSupply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}

	function _calcWithdrawalSharesFromCost(uint256 _cost, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) internal pure returns (uint256 _grossShares, uint256 _feeShares)
	{
		uint256 _netShares = _totalReserve == _totalSupply ? _cost : _cost.mul(_totalSupply).div(_totalReserve);
		_grossShares = _netShares.mul(1e18).div(uint256(1e18).sub(_withdrawalFee));
		_feeShares = _grossShares.sub(_netShares);
		return (_grossShares, _feeShares);
	}

	function _calcWithdrawalCostFromShares(uint256 _grossShares, uint256 _totalReserve, uint256 _totalSupply, uint256 _withdrawalFee) internal pure returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _netShares = _grossShares.mul(uint256(1e18).sub(_withdrawalFee)).div(1e18);
		_cost = _totalReserve == _totalSupply ? _netShares : _netShares.mul(_totalReserve).div(_totalSupply);
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

	function _approveFunds(address _token, address _to, uint256 _amount) internal
	{
		IERC20(_token).safeApprove(_to, _amount);
	}

	function _convertFundsUSDCToDAI(uint256 _amount) internal
	{
		address _swap = Addresses.Curve_COMPOUND;
		address _token = Swap(_swap).underlying_coins(1);
		_approveFunds(_token, _swap, _amount);
		Swap(_swap).exchange_underlying(1, 0, _amount, 0);
	}

	function _convertFundsCOMPToDAI(uint256 _amount) internal
	{
		if (_amount == 0) return;
		address _router = Addresses.UniswapV2_ROUTER02;
		address _token = Addresses.COMP;
		address[] memory _path = new address[](3);
		_path[0] = _token;
		_path[1] = Router02(_router).WETH();
		_path[2] = Addresses.DAI;
		_approveFunds(_token, _router, _amount);
		Router02(_router).swapExactTokensForTokens(_amount, 0, _path, address(this), block.timestamp);
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
		_pool = BFactory(Addresses.Balancer_FACTORY).newBPool();
		IERC20(_token0).safeApprove(_pool, _amount0);
		BPool(_pool).bind(_token0, _amount0, TOKEN0_WEIGHT);
		IERC20(_token1).safeApprove(_pool, _amount1);
		BPool(_pool).bind(_token1, _amount1, TOKEN1_WEIGHT);
		BPool(_pool).setSwapFee(SWAP_FEE);
		BPool(_pool).finalize();
		return _pool;
	}

	function _getPoolBalances(address _pool, address _token0, address _token1) internal view returns (uint256 _amount0, uint256 _amount1)
	{
		uint256 _thisSupply = BPool(_pool).balanceOf(address(this));
		uint256 _totalSupply = BPool(_pool).totalSupply();
		uint256 _balance0 = BPool(_pool).getBalance(_token0);
		uint256 _balance1 = BPool(_pool).getBalance(_token1);
		_amount0 = _balance0.mul(_thisSupply).div(_totalSupply);
		_amount1 = _balance1.mul(_thisSupply).div(_totalSupply);
		return (_amount0, _amount1);
	}

	function _joinPool(address _pool, address _token0, uint256 _amount0, address _token1, uint256 _amount1) internal
	{
		if (_amount0 > 0) {
			IERC20(_token0).safeApprove(_pool, _amount0);
			BPool(_pool).joinswapExternAmountIn(_token0, _amount0, 0);
		}
		if (_amount1 > 0) {
			IERC20(_token1).safeApprove(_pool, _amount1);
			BPool(_pool).joinswapExternAmountIn(_token1, _amount1, 0);
		}
	}

	function _exitPool(address _pool, address _token0, uint256 _amount0, address _token1, uint256 _amount1) internal
	{
		if (_amount0 > 0) {
			BPool(_pool).exitswapExternAmountOut(_token0, _amount0, uint256(-1));
		}
		if (_amount1 > 0) {
			BPool(_pool).exitswapExternAmountOut(_token1, _amount1, uint256(-1));
		}
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

	function totalReserve() public virtual override returns (uint256 _totalReserve)
	{
		return _getBalance(reserveToken);
	}

	function deposit(uint256 _cost) external override nonReentrant
	{
		address _from = msg.sender;
		require(_cost > 0, "deposit cost must be greater than 0");
		(uint256 _netShares, uint256 _feeShares) = calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "deposit shares must be greater than 0");
		_pullFunds(reserveToken, _from, _cost);
		_mint(_from, _netShares);
		_mint(sharesToken, _feeShares.div(2));
		_gulpPoolAssets();
	}

	function withdraw(uint256 _grossShares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "withdrawal shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		require(_cost > 0, "withdrawal cost must be greater than 0");
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

	constructor (address _ctoken) internal
	{
		Comptroller _comptroller = Comptroller(Addresses.Compound_COMPTROLLER);
		address[] memory _ctokens = new address[](1);
		_ctokens[0] = _ctoken;
		uint256 _result = _comptroller.enterMarkets(_ctokens)[0];
		require(_result == 0, "enterMarkets failed");
	}

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

	function _getRedeemAmount(address /* _ctoken */) internal pure returns (uint256 _redeemAmount)
	{
		return 0; // TODO calculate amount available for redeeming
	}

	function _redeem(address _ctoken, uint256 /* _camount */, address /* _token */, uint256 _amount) internal
	{
		uint256 _result = CToken(_ctoken).redeemUnderlying(_amount);
		require(_result == 0, "redeem failure");
	}

	function _getBorrowAmount(address _ctoken) internal returns (uint256 _borrowAmount)
	{
		return CToken(_ctoken).borrowBalanceCurrent(address(this));
	}

	function _borrow(address _ctoken, address /* _token */, uint256 _amount) internal
	{
		uint256 _result = CToken(_ctoken).borrow(_amount);
		require(_result == 0, "borrow failure");
	}

	function _repay(address _ctoken, address _token, uint256 _amount) internal
	{
		IERC20(_token).safeApprove(_ctoken, _amount);
		uint256 _result = CToken(_ctoken).repayBorrow(_amount);
		require(_result == 0, "repay failure");
	}
}

contract GCTokenBase is GTokenBase, GCToken, GCFormulae, CompoundLendingMarketAbstraction
{
	address public immutable underlyingToken;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, address _stakeToken, address _reserveToken)
		GTokenBase(_name, _symbol, _decimals, _stakeToken, _reserveToken) CompoundLendingMarketAbstraction(_reserveToken) public
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
		require(_underlyingCost > 0, "deposit underlying cost must be greater than 0");
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _getExchangeRate(reserveToken, underlyingToken));
		(uint256 _netShares, uint256 _feeShares) = calcDepositSharesFromCost(_cost, totalReserve(), totalSupply(), depositFee());
		require(_netShares > 0, "deposit shares must be greater than 0");
		_pullFunds(underlyingToken, _from, _underlyingCost);
		_mint(_from, _netShares);
		_mint(sharesToken, _feeShares.div(2));
		_lend(reserveToken, _cost, underlyingToken, _underlyingCost);
		_gulpPoolAssets();
	}

	function withdrawUnderlying(uint256 _grossShares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_grossShares > 0, "withdrawal shares must be greater than 0");
		(uint256 _cost, uint256 _feeShares) = calcWithdrawalCostFromShares(_grossShares, totalReserve(), totalSupply(), withdrawalFee());
		uint256 _underlyingCost = _calcUnderlyingCostFromCost(_cost, _getExchangeRate(reserveToken, underlyingToken));
		require(_underlyingCost > 0, "withdrawal underlying cost must be greater than 0");
		_redeem(reserveToken, _cost, underlyingToken, _underlyingCost);
		_pushFunds(underlyingToken, _from, _underlyingCost);
		_burn(_from, _grossShares);
		_mint(sharesToken, _feeShares.div(2));
		_gulpPoolAssets();
	}
}

contract CurveExchangeAbstraction
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	function _C_calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		Swap _swap = Swap(Addresses.Curve_COMPOUND);
		int128 _i = _swap.underlying_coins(0) == _from ? 0 : 1;
		int128 _j = _swap.underlying_coins(0) == _to ? 0 : 1;
		require(_swap.underlying_coins(_i) == _from);
		require(_swap.underlying_coins(_j) == _to);
		if (_inputAmount == 0) return 0;
		return _swap.get_dy_underlying(_i, _j, _inputAmount);
	}

	function _C_calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		Swap _swap = Swap(Addresses.Curve_COMPOUND);
		int128 _i = _swap.underlying_coins(0) == _from ? 0 : 1;
		int128 _j = _swap.underlying_coins(0) == _to ? 0 : 1;
		require(_swap.underlying_coins(_i) == _from);
		require(_swap.underlying_coins(_j) == _to);
		if (_outputAmount == 0) return 0;
		return _swap.get_dx_underlying(_i, _j, _outputAmount);
	}

	function _C_convertBalance(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		Swap _swap = Swap(Addresses.Curve_COMPOUND);
		int128 _i = _swap.underlying_coins(0) == _from ? 0 : 1;
		int128 _j = _swap.underlying_coins(0) == _to ? 0 : 1;
		require(_swap.underlying_coins(_i) == _from);
		require(_swap.underlying_coins(_j) == _to);
		if (_inputAmount == 0) return 0;
		IERC20(_from).safeApprove(Addresses.Curve_COMPOUND, _inputAmount);
		uint256 _balanceBefore = IERC20(_to).balanceOf(address(this));
		_swap.exchange_underlying(_i, _j, _inputAmount, _minOutputAmount);
		uint256 _balanceAfter = IERC20(_to).balanceOf(address(this));
		return _balanceAfter.sub(_balanceBefore);
	}
}

contract UniswapExchangeAbstraction
{
	using SafeERC20 for IERC20;

	function _U_calcConversionOutputFromInput(address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		Router02 _router = Router02(Addresses.UniswapV2_ROUTER02);
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = _router.WETH();
		_path[2] = _to;
		return _router.getAmountsOut(_inputAmount, _path)[2];
	}

	function _U_calcConversionInputFromOutput(address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		Router02 _router = Router02(Addresses.UniswapV2_ROUTER02);
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = _router.WETH();
		_path[2] = _to;
		return _router.getAmountsIn(_outputAmount, _path)[0];
	}

	function _U_convertBalance(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		Router02 _router = Router02(Addresses.UniswapV2_ROUTER02);
		address[] memory _path = new address[](3);
		_path[0] = _from;
		_path[1] = _router.WETH();
		_path[2] = _to;
		IERC20(_from).safeApprove(Addresses.UniswapV2_ROUTER02, _inputAmount);
		return _router.swapExactTokensForTokens(_inputAmount, _minOutputAmount, _path, address(this), uint256(-1))[2];
	}
}

contract gcDAI is GCTokenBase, CurveExchangeAbstraction, UniswapExchangeAbstraction
{
	using SafeMath for uint256;

	uint256 constant IDEAL_COLLATERALIZATION_RATIO = 65e16; // 65%
	uint256 constant LIMIT_COLLATERALIZATION_RATIO = 70e16; // 70%
	uint256 constant LIMIT_ADJUSTMENT_AMOUNT = 1000e18; // $1,000

	address public immutable bonusToken;
	address public immutable borrowToken;
	address public immutable borrowUnderlyingToken;

	bool private enableBorrowStrategy = false;

	constructor ()
		GCTokenBase("growth cDAI", "gcDAI", 18, Addresses.GRO, Addresses.cDAI) public
	{
		bonusToken = Addresses.COMP;
		borrowToken = Addresses.cUSDC;
		borrowUnderlyingToken = _getUnderlyingToken(Addresses.cUSDC);
	}
/*
	function totalReserve() public override returns (uint256 _totalReserve)
	{
		return _calcTotalReserve();
	}

	function setEnableBorrowStrategy(bool _enableBorrowStrategy) public onlyOwner
	{
		enableBorrowStrategy = _enableBorrowStrategy;
	}

	function _gulpBonusAsset() internal
	{
		uint256 _bonusAmount = _getBalance(bonusToken);
		if (_bonusAmount == 0) return;
		uint256 _underlyingCost = _U_calcConversionOutputFromInput(bonusToken, underlyingToken, _bonusAmount);
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _getExchangeRate(reserveToken, underlyingToken));
		_U_convertBalance(bonusToken, underlyingToken, _bonusAmount, _underlyingCost);
		_lend(reserveToken, _cost, underlyingToken, _underlyingCost);
	}

	function _calcTotalReserve() internal returns (uint256 _totalReserve)
	{
		uint256 _cost = _getBalance(reserveToken);
		uint256 _underlyingCost = _calcUnderlyingCostFromCost(_cost, _getExchangeRate(reserveToken, underlyingToken));

		address _borrowUnderlyingToken = _getUnderlyingToken(borrowToken);
		uint256 _borrowAmount = _getBorrowAmount(borrowToken);
		uint256 _borrowedUnderlyingCost = _C_calcConversionInputFromOutput(underlyingToken, _borrowUnderlyingToken, _borrowAmount);

		uint256 _totalReserveUnderlying = _underlyingCost.sub(_borrowedUnderlyingCost);

		return _calcCostFromUnderlyingCost(_totalReserveUnderlying, _getExchangeRate(reserveToken, underlyingToken));
	}

	function _ensureRedeemCost(uint256 _cost) internal
	{
		uint256 _underlyingCost = _calcUnderlyingCostFromCost(_cost, _getExchangeRate(reserveToken, underlyingToken));
		uint256 _availableUnderlyingCost = _getRedeemAmount(reserveToken);
		if (_underlyingCost > _availableUnderlyingCost) {
			uint256 _requiredUnderlyingCost = _underlyingCost.sub(_availableUnderlyingCost);
			_decreaseDebt(_requiredUnderlyingCost);
		}
	}

	function _increaseDebt(uint256 _underlyingCost) internal
	{
		uint256 _borrowCost = _C_calcConversionOutputFromInput(underlyingToken, borrowUnderlyingToken, _underlyingCost);
		_underlyingCost = _C_calcConversionOutputFromInput(borrowUnderlyingToken, underlyingToken, _borrowCost);
		_borrow(borrowToken, borrowUnderlyingToken, _borrowCost);
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _getExchangeRate(reserveToken, underlyingToken));
		_U_convertBalance(borrowUnderlyingToken, underlyingToken, _borrowCost, _underlyingCost);
		_lend(reserveToken, _cost, underlyingToken, _underlyingCost);
	}

	function _decreaseDebt(uint256 _underlyingCost) internal
	{
		uint256 _cost = _calcCostFromUnderlyingCost(_underlyingCost, _getExchangeRate(reserveToken, underlyingToken));
		uint256 _borrowCost = _C_calcConversionOutputFromInput(underlyingToken, borrowUnderlyingToken, _underlyingCost);
		_redeem(reserveToken, _cost, underlyingToken, _underlyingCost);
		_U_convertBalance(underlyingToken, borrowUnderlyingToken, _underlyingCost, _borrowCost);
		_repay(borrowToken, borrowUnderlyingToken, _borrowCost);
	}

	function _adjustBorrowStrategy() internal
	{
		uint256 _cost = _getBalance(reserveToken);
		uint256 _underlyingCost = _calcUnderlyingCostFromCost(_cost, _getExchangeRate(reserveToken, underlyingToken));

		uint256 _borrowAmount = _getBorrowAmount(borrowToken);
		uint256 _borrowedUnderlyingCost = _C_calcConversionInputFromOutput(underlyingToken, borrowUnderlyingToken, _borrowAmount);

		uint256 _idealUnderlyingCost = _underlyingCost.mul(IDEAL_COLLATERALIZATION_RATIO).div(1e18);
		uint256 _limitUnderlyingCost = _underlyingCost.mul(LIMIT_COLLATERALIZATION_RATIO).div(1e18);
		bool _overCollateralized = _borrowedUnderlyingCost < _idealUnderlyingCost;
		bool _underCollateralized = _borrowedUnderlyingCost > _limitUnderlyingCost;

		if (enableBorrowStrategy && _overCollateralized) {
			uint256 _incrementUnderlyingCost = _idealUnderlyingCost.sub(_borrowedUnderlyingCost);
			if (_incrementUnderlyingCost > LIMIT_ADJUSTMENT_AMOUNT) _incrementUnderlyingCost = LIMIT_ADJUSTMENT_AMOUNT;
			_increaseDebt(_incrementUnderlyingCost);
		}
		else
		if (!enableBorrowStrategy) {
			uint256 _decrementUnderlyingCost = _borrowedUnderlyingCost;
			if (_decrementUnderlyingCost > LIMIT_ADJUSTMENT_AMOUNT) _decrementUnderlyingCost = LIMIT_ADJUSTMENT_AMOUNT;
			_decreaseDebt(_decrementUnderlyingCost);
		}
		else
		if (_underCollateralized) {
			uint256 _decrementUnderlyingCost = _borrowedUnderlyingCost.sub(_idealUnderlyingCost);
			if (_decrementUnderlyingCost > LIMIT_ADJUSTMENT_AMOUNT) _decrementUnderlyingCost = LIMIT_ADJUSTMENT_AMOUNT;
			_decreaseDebt(_decrementUnderlyingCost);
		}
	}
*/
}
