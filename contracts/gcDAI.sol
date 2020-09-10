pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { Addresses } from "./Addresses.sol";
import { Factory, Pool } from "./interop/Balancer.sol";
import { Comptroller, PriceOracle, CToken } from "./interop/Compound.sol";
import { Oneinch } from "./interop/Oneinch.sol";

interface GToken is IERC20
{
	function calcMintingShares(uint256 _cost, uint256 _reserve, uint256 _supply, uint256 _fee) external pure returns (uint256 _netShares, uint256 _feeShares);
	function calcMintingCost(uint256 _netShares, uint256 _reserve, uint256 _supply, uint256 _fee) external pure returns (uint256 _cost, uint256 _feeShares);
	function calcBurningShares(uint256 _cost, uint256 _reserve, uint256 _supply, uint256 _fee) external pure returns (uint256 _grossShares, uint256 _feeShares);
	function calcBurningCost(uint256 _grossShares, uint256 _reserve, uint256 _supply, uint256 _fee) external pure returns (uint256 _cost, uint256 _feeShares);
	function calcCostFromUnderlying(uint256 _amount, uint256 _exchangeRate) external pure returns (uint256 _cost);
	function calcUnderlyingFromCost(uint256 _cost, uint256 _exchangeRate) external pure returns (uint256 _amount);

	function totalReserve() external view returns (uint256 _reserve);

	function deposit(uint256 _cost) external;
	function depositUnderlying(uint256 _amount) external;
	function withdraw(uint256 _shares) external;
	function withdrawUnderlying(uint256 _shares) external;
	function burnSwapFees() external;
	function initiateLiquidityMigration(address _recipient) external;
	function completeLiquidityMigration() external;
}

contract gcDAI is ERC20, Ownable, ReentrancyGuard, Addresses, GToken
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 constant MINT_FEE = 1e16; // 1%
	uint256 constant BURN_FEE = 1e16; // 1%

	IERC20 private token = IERC20(DAI);
	CToken private ctoken = CToken(cDAI);

	Pool public pool;

	uint256 public lastFeeBurningTime = 0;

	address public migrationRecipient = address(0);
	uint256 public migrationUnlockTime = uint256(-1);

	constructor () ERC20("growth cDAI", "gcDAI") public
	{
		_setupDecimals(18);
		_initializeOptimalReturns();
	}

	function allocateLiquidityPool(uint256 _stakeAmount, uint256 _sharesAmount) public onlyOwner nonReentrant
	{
		address _from = msg.sender;
		require(address(pool) == address(0), "pool already allocated");
		pool = _createLiquidityPool(_from, _stakeAmount, _sharesAmount);
	}

	function calcMintingShares(uint256 _cost, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _netShares, uint256 _feeShares)
	{
		uint256 _grossShares = _reserve == 0 ? _cost : _cost.mul(_supply).div(_reserve);
		_netShares = _grossShares.mul(1e18).div(_fee.add(1e18));
		_feeShares = _grossShares.sub(_netShares);
		return (_netShares, _feeShares);
	}

	function calcMintingCost(uint256 _netShares, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _grossShares = _netShares.mul(_fee.add(1e18)).div(1e18);
		_cost = _supply == 0 ? _grossShares : _grossShares.mul(_reserve).div(_supply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}

	function calcBurningShares(uint256 _cost, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _grossShares, uint256 _feeShares)
	{
		uint256 _netShares = _reserve == 0 ? _cost : _cost.mul(_supply).div(_reserve);
		_grossShares = _netShares.mul(1e18).div(_fee.sub(1e18));
		_feeShares = _grossShares.sub(_netShares);
		return (_grossShares, _feeShares);
	}

	function calcBurningCost(uint256 _grossShares, uint256 _reserve, uint256 _supply, uint256 _fee) public pure override returns (uint256 _cost, uint256 _feeShares)
	{
		uint256 _netShares = _grossShares.mul(_fee.sub(1e18)).div(1e18);
		_cost = _supply == 0 ? _netShares : _netShares.mul(_reserve).div(_supply);
		_feeShares = _grossShares.sub(_netShares);
		return (_cost, _feeShares);
	}

	function calcCostFromUnderlying(uint256 _amount, uint256 _exchangeRate) public pure override returns (uint256 _cost) {
		return _amount.mul(1e18).div(_exchangeRate);
	}

	function calcUnderlyingFromCost(uint256 _cost, uint256 _exchangeRate) public pure override returns (uint256 _amount) {
		return _cost.mul(_exchangeRate).div(1e18);
	}

	function totalReserve() public view override returns (uint256 _reserve)
	{
		return ctoken.balanceOf(address(this));
	}

	function deposit(uint256 _cost) external override nonReentrant
	{
		address _from = msg.sender;
		require(_cost > 0, "deposit must be greater than 0");

		(uint256 _netShares, uint256 _feeShares) = calcMintingShares(_cost, totalReserve(), totalSupply(), MINT_FEE);

		IERC20(ctoken).safeTransferFrom(_from, address(this), _cost);

		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));
		if (address(pool) != address(0)) _joinLiquidityPool(pool, 0, balanceOf(address(this)));

		_adjustOptimalReturns();
	}

	function depositUnderlying(uint256 _amount) external override nonReentrant
	{
		address _from = msg.sender;
		require(_amount > 0, "deposit must be greater than 0");

		uint256 _cost = calcCostFromUnderlying(_amount, ctoken.exchangeRateCurrent());
		(uint256 _netShares, uint256 _feeShares) = calcMintingShares(_cost, totalReserve(), totalSupply(), MINT_FEE);

		token.safeTransferFrom(_from, address(this), _amount);
		token.safeApprove(address(ctoken), _amount);
		uint256 _result = ctoken.mint(_amount);
		require(_result == 0, "mint failure");

		_mint(_from, _netShares);
		_mint(address(this), _feeShares.div(2));
		if (address(pool) != address(0)) _joinLiquidityPool(pool, 0, balanceOf(address(this)));

		_adjustOptimalReturns();
	}

	function withdraw(uint256 _shares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_shares > 0, "withdraw must be greater than 0");
		require(_shares <= balanceOf(_from), "insufficient balance");

		(uint256 _cost, uint256 _feeShares) = calcBurningCost(_shares, totalReserve(), totalSupply(), BURN_FEE);

		_burn(_from, _shares);
		_mint(address(this), _feeShares.div(2));
		if (address(pool) != address(0)) _joinLiquidityPool(pool, 0, balanceOf(address(this)));

		IERC20(ctoken).safeTransfer(_from, _cost);

		_adjustOptimalReturns();
	}

	function withdrawUnderlying(uint256 _shares) external override nonReentrant
	{
		address _from = msg.sender;
		require(_shares > 0, "withdraw must be greater than 0");
		require(_shares <= balanceOf(_from), "insufficient balance");

		(uint256 _cost, uint256 _feeShares) = calcBurningCost(_shares, totalReserve(), totalSupply(), BURN_FEE);
		uint256 _amount = calcUnderlyingFromCost(_cost, ctoken.exchangeRateCurrent());

		_burn(_from, _shares);
		_mint(address(this), _feeShares.div(2));
		if (address(pool) != address(0)) _joinLiquidityPool(pool, 0, balanceOf(address(this)));

		uint256 _result = ctoken.redeemUnderlying(_amount);
		require(_result == 0, "redeem failure");
		token.safeTransfer(_from, _amount);

		_adjustOptimalReturns();
	}

	function burnSwapFees() external override onlyOwner nonReentrant
	{
		require(address(pool) != address(0), "pool not allocated");
		require(lastFeeBurningTime + 7 days < now, "must wait lock interval");

		// TODO estimate based on swaps
		uint256 _feeStake = 0;
		uint256 _feeShares = 0;

		_exitLiquidityPool(pool, _feeStake, _feeShares);

		IERC20(GRO).safeTransfer(address(0), _feeStake);
		_burn(address(this), _feeShares);

		lastFeeBurningTime = now;
	}

	function initiateLiquidityMigration(address _recipient) external override onlyOwner
	{
		require(address(pool) != address(0), "pool not allocated");
		require(migrationRecipient != address(0), "invalid recipient");
		migrationRecipient = _recipient;
		migrationUnlockTime = now + 7 days;
	}

	function completeLiquidityMigration() external override onlyOwner nonReentrant
	{
		require(migrationRecipient != address(0), "migration not initiated");
		require(migrationUnlockTime < now, "must wait lock interval");

		_migrateLiquidityPool(pool, migrationRecipient);

		migrationRecipient = address(0);
		migrationUnlockTime = uint256(-1);
	}

	/* Borrower code */

	function _initializeOptimalReturns() internal
	{
		Comptroller comptroller = Comptroller(Compound_Comptroller);
		address[] memory ctokens = new address[](1);
		ctokens[0] = address(ctoken);
		uint256[] memory errors = comptroller.enterMarkets(ctokens);
		require(errors[0] == 0, "enterMarkets failed");
	}

	function _adjustOptimalReturns() internal
	{
		Comptroller comptroller = Comptroller(Compound_Comptroller);
		PriceOracle priceOracle = PriceOracle(comptroller.oracle());
		IERC20 utoken = IERC20(USDC);
		CToken btoken = CToken(cUSDC);

		// TODO improve this method to avoid the loop
		for (;;) {
			uint256 _borrowBalance = btoken.borrowBalanceCurrent(address(this));
			(uint256 _error, uint256 _liquidity, uint256 _shortfall) = comptroller.getAccountLiquidity(address(this));
			require(_error == 0, "getAccountLiquidity failed");

			uint256 _usdcPriceInWei = priceOracle.getUnderlyingPrice(address(btoken));
			uint256 _maxBorrowUSDCInWei = _liquidity.mul(1e18).div(_usdcPriceInWei);
			uint256 _numUSDCToBorrow = _maxBorrowUSDCInWei; // TODO be conservative
			if (_numUSDCToBorrow > 0) {
				uint256 _minExpectedDAI = _numUSDCToBorrow; // TODO add a multiplication factor
				uint256 _minExpectedCDAI = calcCostFromUnderlying(_minExpectedDAI, ctoken.exchangeRateCurrent());
				bool _success = _convertBalance(utoken, ctoken, _numUSDCToBorrow, _minExpectedCDAI, true);
				if (_success) {
					uint256 _error = btoken.borrow(_numUSDCToBorrow);
					require(_error == 0, "borrow failure");
					_convertBalance(utoken, ctoken, _numUSDCToBorrow, _minExpectedCDAI, false);
				}
			}
/*
			{
				uint256 _amount = 0;
				utoken.safeApprove(address(btoken), _amount);
        			uint256 _error = btoken.repayBorrow(_amount);
				require(_error == 0, "repayBorrow error");
			}
*/

			break;
		}

		_convertBalance(IERC20(COMP), ctoken, IERC20(COMP).balanceOf(address(this)), 0, false);
	}

	/* DEX abstraction */

	function _convertBalance(IERC20 _from, IERC20 _to, uint256 _amount, uint256 _minAmount, bool _dryRun) internal returns (bool _success)
	{
		if (_amount == 0) return true;
		Oneinch oneinch = Oneinch(Oneinch_Exchange);
		// TODO verify 1inch parts=100 parameter
		(uint256 _returnAmount, uint256[] memory _distribution) = oneinch.getExpectedReturn(_from, _to, _amount, 100, 0);
		if (_returnAmount < _minAmount) return false;
		if (!_dryRun) {
			_from.safeApprove(address(oneinch), _amount);
			oneinch.swap(_from, _to, _amount, _returnAmount, _distribution, 0);
		}
		return true;
	}

	/* LP abstractions */

	uint256 constant POOL_GRO_WEIGHT = 50e16; // 50%
	uint256 constant POOL_GTOKEN_WEIGHT = 50e16; // 50%
	uint256 constant POOL_SWAP_FEE = 10e16; // 10%

	function _createLiquidityPool(address _from, uint256 _stakeAmount, uint256 _sharesAmount) internal returns (Pool _pool)
	{
		IERC20(GRO).safeTransferFrom(_from, address(this), _stakeAmount);
		IERC20(GRO).safeApprove(address(_pool), _stakeAmount);

		IERC20(this).safeTransferFrom(_from, address(this), _sharesAmount);
		IERC20(this).safeApprove(address(_pool), _sharesAmount);

		_pool = Factory(Balancer_Factory).newBPool();
		_pool.bind(GRO, _stakeAmount, POOL_GRO_WEIGHT);
		_pool.bind(address(this), _sharesAmount, POOL_GTOKEN_WEIGHT);
		_pool.setSwapFee(POOL_SWAP_FEE);
		_pool.finalize();
		return _pool;
	}

	function _joinLiquidityPool(Pool _pool, uint256 _stakeAmount, uint256 _sharesAmount) internal
	{
		if (_stakeAmount > 0) {
			IERC20(GRO).safeApprove(address(_pool), _stakeAmount);
			_pool.joinswapExternAmountIn(GRO, _stakeAmount, 0);
		}
		if (_sharesAmount > 0) {
			IERC20(this).safeApprove(address(_pool), _sharesAmount);
			_pool.joinswapExternAmountIn(address(this), _sharesAmount, 0);
		}
	}

	function _exitLiquidityPool(Pool _pool, uint256 _stakeAmount, uint256 _sharesAmount) internal
	{
		if (_stakeAmount > 0) {
			_pool.exitswapExternAmountOut(GRO, _stakeAmount, uint256(-1));
		}
		if (_sharesAmount > 0) {
			_pool.exitswapExternAmountOut(address(this), _sharesAmount, uint256(-1));
		}
	}

	function _migrateLiquidityPool(Pool _pool, address _recipient) internal
	{
		IERC20(_pool).safeTransfer(_recipient, _pool.balanceOf(address(this)));
	}
}
