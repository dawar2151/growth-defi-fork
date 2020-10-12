const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCDelegatedReserveManager = artifacts.require('GCDelegatedReserveManager');
const gcDAI = artifacts.require('gcDAI');
const gcZRX = artifacts.require('gcZRX');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');
const IERC20 = artifacts.require('IERC20');

module.exports = async (deployer, network) => {
  deployer.link(G, gcZRX);
  deployer.link(GLiquidityPoolManager, gcZRX);
  deployer.link(GCDelegatedReserveManager, gcZRX);
  const gctoken = await gcDAI.deployed();
  await deployer.deploy(gcZRX, gctoken.address);
  let exchange
  if (['mainnet', 'development', 'testing'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
  const token = await gcZRX.deployed();
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
    // TODO fix
    // await token.depositUnderlying(uamount);
    // await token.allocateLiquidityPool(samount, gamount);
  }
};
