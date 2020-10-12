const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCLeveragedReserveManager = artifacts.require('GCLeveragedReserveManager');
const gcUSDC = artifacts.require('gcUSDC');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');
const IERC20 = artifacts.require('IERC20');

module.exports = async (deployer, network) => {
  deployer.link(G, gcUSDC);
  deployer.link(GLiquidityPoolManager, gcUSDC);
  deployer.link(GCLeveragedReserveManager, gcUSDC);
  await deployer.deploy(gcUSDC);
  let exchange
  if (['mainnet', 'development', 'testing'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
  const token = await gcUSDC.deployed();
  await token.setExchange(exchange.address);
  await token.setMiningGulpRange('20000000000000000000', '500000000000000000000');
  if (['development', 'testing'].includes(network)) {
    const GRO = await token.stakesToken();
    const cUSDC = await token.reserveToken();
    const exchange = await GUniswapV2Exchange.deployed();
    await exchange.faucet(GRO, '1000000', { value: '1000000000000000000' });
    await exchange.faucet(cUSDC, '1000000', { value: '1000000000000000000' });
    await (await IERC20.at(GRO)).approve(token.address, '1000000');
    await (await IERC20.at(cUSDC)).approve(token.address, '1000000');
    await token.deposit('1000000');
    await token.allocateLiquidityPool('1000000', '1000000');
  }
};
