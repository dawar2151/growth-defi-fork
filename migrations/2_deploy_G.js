const G = artifacts.require('G');

module.exports = async (deployer) => {
  await deployer.deploy(G);
};
