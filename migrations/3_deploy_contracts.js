const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');

module.exports = (deployer) => {
  deployer.link(G, GLiquidityPoolManager);
  deployer.deploy(GLiquidityPoolManager);
};
