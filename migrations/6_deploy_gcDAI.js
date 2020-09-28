const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCLeveragedReserveManager = artifacts.require('GCLeveragedReserveManager');
const gcDAI = artifacts.require('gcDAI');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');

module.exports = async (deployer, network) => {
  deployer.link(G, gcDAI);
  deployer.link(GLiquidityPoolManager, gcDAI);
  deployer.link(GCLeveragedReserveManager, gcDAI);
  await deployer.deploy(gcDAI);
  let exchange
  if (['mainnet', 'development'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
  const token = await gcDAI.deployed();
  await token.setMiningExchange(exchange.address);
  await token.setMiningGulpRange('20000000000000000000', '500000000000000000000');
};
