const GSushiswapExchange = artifacts.require('GSushiswapExchange');
const GUniswapV2Exchange = artifacts.require('GUniswapV2Exchange');

module.exports = (deployer) => {
  deployer.deploy(GSushiswapExchange);
  deployer.deploy(GUniswapV2Exchange);
};
