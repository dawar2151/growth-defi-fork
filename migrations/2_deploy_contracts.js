const gcDAI = artifacts.require('gcDAI');

module.exports = function(deployer) {
  deployer.deploy(gcDAI);
};
