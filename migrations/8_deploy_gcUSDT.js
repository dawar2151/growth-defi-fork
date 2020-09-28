const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCLeveragedReserveManager = artifacts.require('GCLeveragedReserveManager');
const gcUSDT = artifacts.require('gcUSDT');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');

module.exports = async (deployer, network) => {
  deployer.link(G, gcUSDT);
  deployer.link(GLiquidityPoolManager, gcUSDT);
  deployer.link(GCLeveragedReserveManager, gcUSDT);
  await deployer.deploy(gcUSDT);
  let exchange
  if (['mainnet', 'development'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
  const token = await gcUSDT.deployed();
  await token.setMiningExchange(exchange.address);
  await token.setMiningGulpRange('20000000000000000000', '500000000000000000000');
};
