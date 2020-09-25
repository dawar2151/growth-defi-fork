const G = artifacts.require('G');
const GLiquidityPoolManager = artifacts.require('GLiquidityPoolManager');
const GCLeveragedReserveManager = artifacts.require('GCLeveragedReserveManager');
const gcDAI = artifacts.require('gcDAI');

module.exports = async (deployer) => {
  deployer.link(G, gcDAI);
  deployer.link(GLiquidityPoolManager, gcDAI);
  deployer.link(GCLeveragedReserveManager, gcDAI);
  await deployer.deploy(gcDAI);
  const token = await gcDAI.deployed();
  await token.setMiningGulpRange('20000000000000000000', '500000000000000000000');
};
