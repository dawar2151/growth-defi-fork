const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCDelegatedReserveManager = artifacts.require('GCDelegatedReserveManager');
const gcDAI = artifacts.require('gcDAI');
const gcBAT = artifacts.require('gcBAT');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');

module.exports = async (deployer, network) => {
  deployer.link(G, gcBAT);
  deployer.link(GLiquidityPoolManager, gcBAT);
  deployer.link(GCDelegatedReserveManager, gcBAT);
  const gctoken = await gcDAI.deployed();
  await deployer.deploy(gcBAT, gctoken.address);
  let exchange
  if (['mainnet', 'development', 'testing'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
  const token = await gcBAT.deployed();
  await token.setExchange(exchange.address);
  await token.setMiningGulpRange('20000000000000000000', '500000000000000000000');
  await token.setGrowthGulpRange('10000000000000000000000', '20000000000000000000000');
};
