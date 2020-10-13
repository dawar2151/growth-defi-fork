const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCDelegatedReserveManager = artifacts.require('GCDelegatedReserveManager');
const gcDAI = artifacts.require('gcDAI');
const gcETH = artifacts.require('gcETH');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');
const IERC20 = artifacts.require('IERC20');

module.exports = async (deployer, network) => {
  deployer.link(G, gcETH);
  deployer.link(GLiquidityPoolManager, gcETH);
  deployer.link(GCDelegatedReserveManager, gcETH);
  const gctoken = await gcDAI.deployed();
  await deployer.deploy(gcETH, gctoken.address);
  let exchange
  if (['mainnet', 'development', 'testing'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
  const token = await gcETH.deployed();
  await token.setExchange(exchange.address);
  await token.setMiningGulpRange(`${20e18}`, `${500e18}`);
  await token.setGrowthGulpRange('10000000000000000000000', '20000000000000000000000');
  if (['development', 'testing'].includes(network)) {
    const value = `${1e18}`;
    const exchange = await GUniswapV2Exchange.deployed();
    const stoken = await IERC20.at(await token.stakesToken());
    const utoken = await IERC20.at(await token.underlyingToken());
    const samount = `${1e6}`;
    const gamount = `${1e6}`;
    const { '0': uamount } = await token.calcDepositUnderlyingCostFromShares(`${1e7}`, '0', '0', '0', await token.exchangeRate());
    await exchange.faucet(stoken.address, samount, { value });
    await exchange.faucet(utoken.address, uamount, { value });
    await stoken.approve(token.address, samount);
    await utoken.approve(token.address, uamount);
    await token.depositUnderlying(uamount);
    await token.allocateLiquidityPool(samount, gamount);
  }
};
