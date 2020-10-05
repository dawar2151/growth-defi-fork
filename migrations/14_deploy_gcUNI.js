const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCDelegatedReserveManager = artifacts.require('GCDelegatedReserveManager');
const gcDAI = artifacts.require('gcDAI');
const gcUNI = artifacts.require('gcUNI');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');

module.exports = async (deployer, network) => {
  deployer.link(G, gcUNI);
  deployer.link(GLiquidityPoolManager, gcUNI);
  deployer.link(GCDelegatedReserveManager, gcUNI);
  const gctoken = await gcDAI.deployed();
  await deployer.deploy(gcUNI, gctoken.address);
  let exchange
  if (['mainnet', 'development'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
  const token = await gcUNI.deployed();
  await token.setExchange(exchange.address);
  await token.setMiningGulpRange('20000000000000000000', '500000000000000000000');
  await token.setGrowthGulpRange('1000000000000000000', '1000000000000000000');
};
