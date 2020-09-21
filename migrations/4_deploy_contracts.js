const G = artifacts.require('G');
const GCLeveragedReserveManager = artifacts.require('GCLeveragedReserveManager');

module.exports = (deployer) => {
  deployer.link(G, GCLeveragedReserveManager);
  deployer.deploy(GCLeveragedReserveManager);
};
