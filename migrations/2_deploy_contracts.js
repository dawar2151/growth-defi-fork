const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCLeveragedReserveManager = artifacts.require('GCLeveragedReserveManager');
const gcDAI = artifacts.require('gcDAI');

module.exports = (deployer) => {
  deployer.deploy(G);
  deployer.link(G, GLiquidityPoolManager);
  deployer.link(G, GCLeveragedReserveManager);
  deployer.link(G, gcDAI);
  deployer.deploy(GLiquidityPoolManager);
  deployer.link(GLiquidityPoolManager, gcDAI);
  deployer.deploy(GCLeveragedReserveManager);
  deployer.link(GCLeveragedReserveManager, gcDAI);
  deployer.deploy(gcDAI);
};
