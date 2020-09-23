const gcDAI = artifacts.require('gcDAI');
const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');

module.exports = async (deployer, network) => {
  const token = await gcDAI.deployed();
  await deployer.deploy(GSushiswapExchange);
  await deployer.deploy(GUniswapV2Exchange);
  let exchange
  if (['mainnet', 'development'].includes(network)) {
    exchange = await GSushiswapExchange.deployed();
  } else {
    exchange = await GUniswapV2Exchange.deployed();
  }
//  await token.setMiningExchange(exchange.address);
};
