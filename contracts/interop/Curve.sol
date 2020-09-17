// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
interface Registry
{
	struct PoolCoins {
		address[8] coins;
		address[8] underlying_coins;
		uint256[8] decimals;
		uint256[8] underlying_decimals;
	}

	struct PoolInfo {
		uint256[8] balances;
		uint256[8] underlying_balances;
		uint256[8] decimals;
		uint256[8] underlying_decimals;
		address lp_token;
		uint256 A;
		uint256 fee;
	}

	function find_pool_for_coins(address _from, address _to) external view returns (address _pool);
	function find_pool_for_coins(address _from, address _to, uint256 _i) external view returns (address _pool);
	function get_pool_coins(address _pool) external view returns (PoolCoins calldata _pool_coins);
	function estimate_gas_used(address _pool, address _from, address _to) external view returns (uint256 _gas);
	function get_exchange_amount(address _pool, address _from, address _to, uint256 _amount) external view returns (uint256 _exchange_amount);
	function get_calculator(address _pool) external view returns (address _calculator);
	function admin() external view returns (address _admin);
	function pool_list(int128 _i) external view returns (address _pool_list);
	function pool_count() external view returns (uint256 _pool_count);

	function get_pool_info(address _pool) external returns (PoolInfo calldata _pool_info);
	function get_pool_rates(address _pool) external returns (uint256[8] calldata _rates);
	function exchange(address _pool, address _from, address _to, uint256 _amount, uint256 _expected) external payable returns (bool _success);
	function get_input_amount(address _pool, address _from, address _to, uint256 _amount) external returns (uint256 _input_amount);
	function get_exchange_amounts(address _pool, address _from, address _to, uint256[100] calldata _amounts) external returns (uint256[100] calldata _exchange_amounts);
	function add_pool(address _pool, int128 _n_coins, address _lp_token, address _calculator, bytes32 _rate_method_id, bytes32 _decimals, bytes32 _underlying_decimals) external;
	function add_pool_without_underlying(address _pool, int128 _n_coins, address _lp_token, address _calculator, bytes32 _rate_method_id, bytes32 _decimals, bytes32 _use_rates) external;
	function remove_pool(address _pool) external;
	function set_returns_none(address _addr, bool _is_returns_none) external;
	function set_pool_gas_estimates(address[5] calldata _addr, uint256[2][5] calldata _amount) external;
	function set_coin_gas_estimates(address[10] calldata _addr, uint256[10] calldata _amount) external;
	function set_gas_estimate_contract(address _pool, address _estimator) external;
	function set_calculator(address _pool, address _calculator) external;
	function commit_transfer_ownership(address _new_admin) external;
	function apply_transfer_ownership() external;
	function revert_transfer_ownership() external;
	function claim_token_balance(address _token) external;
	function claim_eth_balance() external;

	event TokenExchange(address indexed _buyer, address indexed _pool, address _token_sold, address _token_bought, uint256 _amount_sold, uint256 _amount_bought);
	event CommitNewAdmin(uint256 indexed _deadline, address indexed _admin);
	event NewAdmin(address indexed _admin);
	event PoolAdded(address indexed _pool, bytes _rate_method_id);
	event PoolRemoved(address indexed _pool);
}

interface Calculator
{
	function get_dx(int128 _n_coins, uint256[8] calldata _balances, uint256 _amp, uint256 _fee, uint256[8] calldata _rates, uint256[8] calldata _precisions, bool _underlying, int128 _i, int128 _j, uint256 _dy) external view returns (uint256 _dx);
	function get_dy(int128 _n_coins, uint256[8] calldata _balances, uint256 _amp, uint256 _fee, uint256[8] calldata _rates, uint256[8] calldata _precisions, bool _underlying, int128 _i, int128 _j, uint256[100] calldata _dx) external view returns (uint256[100] calldata _dy);
}
*/
interface Swap
{
/*
	function coins(int128 _i) external view returns (address _coin);
*/
	function underlying_coins(int128 _i) external view returns (address _underlying_coin);
/*
	function balances(int128 _i) external view returns (uint256 _balance);
	function A() external view returns (uint256 _A);
	function fee() external view returns (uint256 _fee);
	function admin_fee() external view returns (uint256 _admin_fee);
	function owner() external view returns (address _owner);
	function future_A() external view returns (uint256 _future_A);
	function future_A_time() external view returns (uint256 _future_A_time);
	function future_fee() external view returns (uint256 _future_fee);
	function future_admin_fee() external view returns (uint256 _future_admin_fee);
	function future_owner() external view returns (address _future_owner);
	function initial_A() external view returns (uint256 _initial_A);
	function initial_A_time() external view returns (uint256 _initial_A_time);
	function admin_actions_deadline() external view returns (uint256 _admin_actions_deadline);
	function transfer_ownership_deadline() external view returns (uint256 _transfer_ownership_deadline);
	function get_virtual_price() external view returns (uint256 _virtual_price);
	function get_dx(int128 _i, int128 _j, uint256 _dy) external view returns (uint256 _dx);
	function get_dy(int128 _i, int128 _j, uint256 _dx) external view returns (uint256 _dy);
*/
	function get_dx_underlying(int128 _i, int128 _j, uint256 _dy) external view returns (uint256 _dx);
	function get_dy_underlying(int128 _i, int128 _j, uint256 _dx) external view returns (uint256 _dy);
/*
	function calc_token_amount(uint256[2] calldata _amounts, bool _deposit) external view returns (uint256 _amount);
	function calc_token_amount(uint256[3] calldata _amounts, bool _deposit) external view returns (uint256 _amount);
	function calc_token_amount(uint256[4] calldata _amounts, bool _deposit) external view returns (uint256 _amount);
	function calc_withdraw_one_coin(uint256 _token_amount, int128 _i) external view returns (uint256 _amount);

	function exchange(int128 _i, int128 _j, uint256 _dx, uint256 _min_dy) external;
*/
	function exchange_underlying(int128 _i, int128 _j, uint256 _dx, uint256 _min_dy) external;
/*
	function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external;
	function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external;
	function add_liquidity(uint256[4] calldata _amounts, uint256 _min_mint_amount) external;
	function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external;
	function remove_liquidity(uint256 _amount, uint256 _deadline, uint256[3] calldata _min_amounts) external;
	function remove_liquidity(uint256 _amount, uint256 _deadline, uint256[4] calldata _min_amounts) external;
	function remove_liquidity_imbalance(uint256[2] calldata _amounts, uint256 _max_burn_amount) external;
	function remove_liquidity_imbalance(uint256[3] calldata _amounts, uint256 _max_burn_amount) external;
	function remove_liquidity_imbalance(uint256[4] calldata _amounts, uint256 _max_burn_amount) external;
	function remove_liquidity_one_coin(uint256 _token_amount, int128 _i, uint256 _min_amount) external;

	function commit_transfer_ownership(address _owner) external;
	function apply_transfer_ownership() external;
	function revert_transfer_ownership() external;
	function commit_new_fee(uint256 _new_fee, uint256 _new_admin_fee) external;
	function apply_new_fee() external;
	function commit_new_parameters(uint256 _amplification, uint256 _new_fee, uint256 _new_admin_fee) external;
	function apply_new_parameters() external;
	function revert_new_parameters() external;
	function withdraw_admin_fees() external;
	function kill_me() external;
	function unkill_me() external;
	function ramp_A(uint256 _future_A, uint256 _future_time) external;
	function stop_ramp_A() external;

	event TokenExchange(address indexed _buyer, int128 _sold_id, uint256 _tokens_sold, int128 _bought_id, uint256 _tokens_bought);
	event TokenExchangeUnderlying(address indexed _buyer, int128 _sold_id, uint256 _tokens_sold, int128 _bought_id, uint256 _tokens_bought);
	event AddLiquidity(address indexed _provider, uint256[2] _token_amounts, uint256[2] _fees, uint256 _invariant, uint256 _token_supply);
	event AddLiquidity(address indexed _provider, uint256[3] _token_amounts, uint256[3] _fees, uint256 _invariant, uint256 _token_supply);
	event AddLiquidity(address indexed _provider, uint256[4] _token_amounts, uint256[4] _fees, uint256 _invariant, uint256 _token_supply);
	event RemoveLiquidity(address indexed _provider, uint256[2] _token_amounts, uint256[2] _fees, uint256 _token_supply);
	event RemoveLiquidity(address indexed _provider, uint256[3] _token_amounts, uint256[3] _fees, uint256 _token_supply);
	event RemoveLiquidity(address indexed _provider, uint256[4] _token_amounts, uint256[4] _fees, uint256 _token_supply);
	event RemoveLiquidityImbalance(address indexed _provider, uint256[2] _token_amounts, uint256[2] _fees, uint256 _invariant, uint256 _token_supply);
	event RemoveLiquidityImbalance(address indexed _provider, uint256[3] _token_amounts, uint256[3] _fees, uint256 _invariant, uint256 _token_supply);
	event RemoveLiquidityImbalance(address indexed _provider, uint256[4] _token_amounts, uint256[4] _fees, uint256 _invariant, uint256 _token_supply);
	event RemoveLiquidityOne(address indexed _provider, uint256 _token_amount, uint256 _coin_amount);
	event CommitNewAdmin(uint256 indexed _deadline, address indexed _admin);
	event NewAdmin(address indexed _admin);
	event CommitNewFee (uint256 indexed _deadline, uint256 _fee, uint256 _admin_fee);
	event NewFee(uint256 _fee, uint256 _admin_fee);
	event CommitNewParameters(uint256 indexed _deadline, uint256 _A, uint256 _fee, uint256 _admin_fee);
	event NewParameters(uint256 _A, uint256 _fee, uint256 _admin_fee);
	event RampA(uint256 _old_A, uint256 _new_A, uint256 _initial_time, uint256 _future_time);
	event StopRampA(uint256 _A, uint256 _t);
*/
}
/*
interface Token is IERC20
{
	function set_minter(address _minter) external;
	function mint(address _to, uint256 _value) external;
	function burn(uint256 _value) external;
	function burnFrom(address _to, uint256 _value) external;
}

interface Deposit
{
	function curve() external view returns (address _curve);
	function token() external view returns (address _token);
	function coins(int128 _i) external view returns (address _coin);
	function underlying_coins(int128 _i) external view returns (address _underlying_coin);
	function calc_withdraw_one_coin(uint256 _token_amount, int128 _i) external view returns (uint256 _amount);

	function add_liquidity(uint256[2] calldata _uamounts, uint256 _min_mint_amount) external;
	function add_liquidity(uint256[3] calldata _uamounts, uint256 _min_mint_amount) external;
	function add_liquidity(uint256[4] calldata _uamounts, uint256 _min_mint_amount) external;
	function remove_liquidity(uint256 _amount, uint256[2] calldata _min_uamounts) external;
	function remove_liquidity(uint256 _amount, uint256[3] calldata _min_uamounts) external;
	function remove_liquidity(uint256 _amount, uint256[4] calldata _min_uamounts) external;
	function remove_liquidity_imbalance(uint256[2] calldata _uamounts, uint256 _max_burn_amount) external;
	function remove_liquidity_imbalance(uint256[3] calldata _uamounts, uint256 _max_burn_amount) external;
	function remove_liquidity_imbalance(uint256[4] calldata _uamounts, uint256 _max_burn_amount) external;
	function remove_liquidity_one_coin(uint256 _token_amount, int128 _i, uint256 _min_uamount) external;
	function remove_liquidity_one_coin(uint256 _token_amount, int128 _i, uint256 _min_uamount, bool _donate_dust) external;
	function withdraw_donated_dust() external;
}

interface Rewards
{
	function DURATION() external view returns (uint256 _DURATION);
	function balanceOf(address _account) external view returns (uint256 _amount);
	function earned(address _account) external view returns (uint256 _amount);
	function getRewardForDuration() external view returns (uint256 _rewardForDuration);
	function isOwner() external view returns (bool _isOwner);
	function lastTimeRewardApplicable() external view returns (uint256 _lastTimeRewardApplicable);
	function lastUpdateTime() external view returns (uint256 _lastUpdateTime);
	function nominatedOwner() external view returns (address _nominatedOwner);
	function owner() external view returns (address _owner);
	function periodFinish() external view returns (uint256 _periodFinish);
	function rewardPerToken() external view returns (uint256 _rewardPerToken);
	function rewardPerTokenStored() external view returns (uint256 _rewardPerTokenStored);
	function rewardRate() external view returns (uint256 _rewardRate);
	function rewards(address _account) external view returns (uint256 _rewards);
	function rewardsDistribution() external view returns (address _rewardsDistribution);
	function rewardsToken() external view returns (address _rewardsToken);
	function snx() external view returns (address _snx);
	function stakingToken() external view returns (address _stakingToken);
	function totalSupply() external view returns (uint256 _totalSupply);
	function uni() external view returns (address _uni);
	function userRewardPerTokenPaid(address _account) external view returns (uint256 _rewards);

	function acceptOwnership() external;
	function exit() external;
	function getReward() external;
	function nominateNewOwner(address _owner) external;
	function notifyRewardAmount(uint256 _reward) external;
	function renounceOwnership() external;
	function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external;
	function setRewardsDistribution(address _rewardsDistribution) external;
	function stake(uint256 _amount) external;
	function transferOwnership(address _newOwner) external;
	function withdraw(uint256 _amount) external;

	event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
	event OwnerChanged(address _oldOwner, address _newOwner);
	event OwnerNominated(address _newOwner);
	event Recovered(address indexed _token, uint256 _amount);
	event RewardAdded(uint256 _reward);
	event RewardPaid(address indexed _user, uint256 _reward);
	event Staked(address indexed _user, uint256 _amount);
	event Withdrawn(address indexed _user, uint256 _amount);
}

interface Adapter
{
	function acceptRelayedCall(address _relay, address _from, bytes calldata _encodedFunction, uint256 _transactionFee, uint256 _gasPrice, uint256 _gasLimit, uint256 _nonce, bytes calldata _approvalData, uint256 _maxPossibleCharge) external view returns (uint256 _result, bytes calldata _data);
	function getHubAddr() external view returns (address _addr);
	function relayHubVersion() external view returns (string calldata _version);

	function chi() external returns (address _chi);
	function exchange() external returns (address _exchange);
	function executeMetaTransaction(address _userAddress, bytes calldata _functionSignature, string calldata _message, string calldata _length, bytes32 _sigR, bytes32 _sigS, uint8 _sigV) external returns (bytes calldata _result);
	function getChainID() external returns (uint256 _chainID);
	function getNonce(address _user) external returns (uint256 _nonce);
	function mintNoDeposit(address _wbtcDestination, uint256 _amount, uint256[2] calldata _amounts, uint256 _min_mint_amount, uint256 _new_min_mint_amount, bytes32 _nHash, bytes calldata _sig) external;
	function mintNoDeposit(address _wbtcDestination, uint256 _amount, uint256[3] calldata _amounts, uint256 _min_mint_amount, uint256 _new_min_mint_amount, bytes32 _nHash, bytes calldata _sig) external;
	function mintThenDeposit(address _wbtcDestination, uint256 _amount, uint256[2] calldata _amounts, uint256 _min_mint_amount, uint256 _new_min_mint_amount, bytes32 _nHash, bytes calldata _sig) external;
	function mintThenDeposit(address _wbtcDestination, uint256 _amount, uint256[3] calldata _amounts, uint256 _min_mint_amount, uint256 _new_min_mint_amount, bytes32 _nHash, bytes calldata _sig) external;
	function mintNoSwap(uint256 _minExchangeRate, uint256 _newMinExchangeRate, uint256 _slippage, address _wbtcDestination, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external;
	function mintThenSwap(uint256 _minExchangeRate, uint256 _newMinExchangeRate, uint256 _slippage, address _wbtcDestination, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external;
	function mintThenSwap(uint256 _minExchangeRate, uint256 _newMinExchangeRate, uint256 _slippage, int128 _j, address _coinDestination, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external;
	function recoverStuck(bytes calldata _encoded, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external;
	function preRelayedCall(bytes calldata _context) external returns (bytes32 _result);
	function postRelayedCall(bytes calldata _context, bool _success, uint256 _actualCharge, bytes32 _preRetVal) external;
	function registry() external returns (address _registry);
	function removeLiquidityImbalanceThenBurn(bytes calldata _btcDestination, uint256[2] calldata _amounts, uint256 _max_burn_amount) external;
	function removeLiquidityImbalanceThenBurn(bytes calldata _btcDestination, uint256[3] calldata _amounts, uint256 _max_burn_amount) external;
	function removeLiquidityImbalanceThenBurn(bytes calldata _btcDestination, address _coinDestination, uint256[2] calldata _amounts, uint256 _max_burn_amount) external;
	function removeLiquidityImbalanceThenBurn(bytes calldata _btcDestination, address _coinDestination, uint256[3] calldata _amounts, uint256 _max_burn_amount) external;
	function removeLiquidityThenBurn(bytes calldata _btcDestination, uint256 _amount, uint256[2] calldata _min_amounts) external;
	function removeLiquidityThenBurn(bytes calldata _btcDestination, uint256 _amount, uint256[3] calldata _min_amounts) external;
	function removeLiquidityThenBurn(bytes calldata _btcDestination, address _coinDestination, uint256 _amount, uint256[2] calldata _min_amounts) external;
	function removeLiquidityThenBurn(bytes calldata _btcDestination, address _coinDestination, uint256 _amount, uint256[3] calldata _min_amounts) external;
	function removeLiquidityOneCoinThenBurn(bytes calldata _btcDestination, uint256 _token_amounts, uint256 _min_amount) external;
	function removeLiquidityOneCoinThenBurn(bytes calldata _btcDestination, uint256 _token_amounts, uint256 _min_amount, uint8 _i) external;
	function swapThenBurn(bytes calldata _btcDestination, uint256 _amount, uint256 _minRenbtcAmount) external;
	function swapThenBurn(bytes calldata _btcDestination, uint256 _amount, uint256 _minRenbtcAmount, uint8 _i) external;
	function verify(address _owner, string calldata _message, string calldata _length, uint256 _nonce, uint256 _chainID, bytes32 _sigR, bytes32 _sigS, uint8 _sigV) external returns (bool _success);

	event Burn(uint256 _burnAmount);
	event DepositMintedCurve(uint256 _mintedAmount, uint256 _curveAmount);
	event DepositMintedCurve(uint256 _mintedAmount, uint256 _curveAmount, uint256[2] _amounts);
	event DepositMintedCurve(uint256 _mintedAmount, uint256 _curveAmount, uint256[3] _amounts);
	event MetaTransactionExecuted(address _userAddress, address _relayerAddress, bytes _functionSignature);
	event ReceiveRen(uint256 _renAmount);
	event RelayHubChanged(address indexed _oldRelayHub, address indexed _newRelayHub);
	event SwapReceived(uint256 _mintedAmount, uint256 _wbtcAmount);
	event SwapReceived(uint256 _mintedAmount, uint256 _erc20BTCAmount, int128 _j);
}
*/
