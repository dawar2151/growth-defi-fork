const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');

module.exports = async (deployer) => {
  await deployer.deploy(GSushiswapExchange);
  await deployer.deploy(GUniswapV2Exchange);
};
