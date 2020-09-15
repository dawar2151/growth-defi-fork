const gcDAI = artifacts.require('gcDAI');

module.exports = (deployer) => {
  deployer.deploy(gcDAI);
};
