const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCLeveragedReserveManager = artifacts.require('GCLeveragedReserveManager');
const gcDAI = artifacts.require('gcDAI');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');
const IERC20 = artifacts.require('IERC20');

module.exports = async (deployer, network) => {
  deployer.link(G, gcDAI);
  deployer.link(GLiquidityPoolManager, gcDAI);
  deployer.link(GCLeveragedReserveManager, gcDAI);
  await deployer.deploy(gcDAI);
  let exchange
  if (['mainnet', 'development', 'testing'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
  const token = await gcDAI.deployed();
  await token.setExchange(exchange.address);
  await token.setMiningGulpRange('20000000000000000000', '500000000000000000000');
  if (['development', 'testing'].includes(network)) {
    const GRO = await token.stakesToken();
    const cDAI = await token.reserveToken();
    const exchange = await GUniswapV2Exchange.deployed();
    await exchange.faucet(GRO, '1000000', { value: '1000000000000000000' });
    await exchange.faucet(cDAI, '1000000', { value: '1000000000000000000' });
    await (await IERC20.at(GRO)).approve(token.address, '1000000');
    await (await IERC20.at(cDAI)).approve(token.address, '1000000');
    await token.deposit('1000000');
    await token.allocateLiquidityPool('1000000', '1000000');
  }
};
