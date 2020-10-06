const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCDelegatedReserveManager = artifacts.require('GCDelegatedReserveManager');
const gcDAI = artifacts.require('gcDAI');
const gcZRX = artifacts.require('gcZRX');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');

module.exports = async (deployer, network) => {
  deployer.link(G, gcZRX);
  deployer.link(GLiquidityPoolManager, gcZRX);
  deployer.link(GCDelegatedReserveManager, gcZRX);
  const gctoken = await gcDAI.deployed();
  await deployer.deploy(gcZRX, gctoken.address);
  let exchange
  if (['mainnet', 'development'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
  const token = await gcZRX.deployed();
  await token.setExchange(exchange.address);
  await token.setMiningGulpRange('20000000000000000000', '500000000000000000000');
  await token.setGrowthGulpRange('10000000000000000000000', '20000000000000000000000');
};
