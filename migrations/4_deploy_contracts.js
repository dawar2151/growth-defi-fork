const G = artifacts.require('G');
const GCLeveragedReserveManager = artifacts.require('GCLeveragedReserveManager');

module.exports = async (deployer) => {
  deployer.link(G, GCLeveragedReserveManager);
  await deployer.deploy(GCLeveragedReserveManager);
};
