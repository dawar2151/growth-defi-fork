const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCLeveragedReserveManager = artifacts.require('GCLeveragedReserveManager');
const gcDAI = artifacts.require('gcDAI');

module.exports = async (deployer) => {
  deployer.link(G, gcDAI);
  deployer.link(GLiquidityPoolManager, gcDAI);
  deployer.link(GCLeveragedReserveManager, gcDAI);
  await deployer.deploy(gcDAI);
};
