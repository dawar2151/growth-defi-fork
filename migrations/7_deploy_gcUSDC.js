const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCLeveragedReserveManager = artifacts.require('GCLeveragedReserveManager');
const gcUSDC = artifacts.require('gcUSDC');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');

module.exports = async (deployer, network) => {
  deployer.link(G, gcUSDC);
  deployer.link(GLiquidityPoolManager, gcUSDC);
  deployer.link(GCLeveragedReserveManager, gcUSDC);
  await deployer.deploy(gcUSDC);
  let exchange
  if (['mainnet', 'development'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
  const token = await gcUSDC.deployed();
  await token.setMiningExchange(exchange.address);
  await token.setMiningGulpRange('20000000000000000000', '500000000000000000000');
};
