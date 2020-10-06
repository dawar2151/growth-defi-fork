const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCDelegatedReserveManager = artifacts.require('GCDelegatedReserveManager');
const gcDAI = artifacts.require('gcDAI');
const gcETH = artifacts.require('gcETH');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');

module.exports = async (deployer, network) => {
  deployer.link(G, gcETH);
  deployer.link(GLiquidityPoolManager, gcETH);
  deployer.link(GCDelegatedReserveManager, gcETH);
  const gctoken = await gcDAI.deployed();
  await deployer.deploy(gcETH, gctoken.address);
  let exchange
  if (['mainnet', 'development'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
  const token = await gcETH.deployed();
  await token.setExchange(exchange.address);
  await token.setMiningGulpRange('20000000000000000000', '500000000000000000000');
  await token.setGrowthGulpRange('10000000000000000000000', '20000000000000000000000');
};
