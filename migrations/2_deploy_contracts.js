// const Addresses = artifacts.require('Addresses');
const GTokenBase = artifacts.require('GTokenBase');
// const gcDAI = artifacts.require('gcDAI');

module.exports = (deployer) => {
  const stakeToken = '0xFcB74f30d8949650AA524d8bF496218a20ce2db4';
  const reserveToken = '0xF0d0EB522cfa50B716B3b1604C4F0fA6f04376AD';
  deployer.deploy(GTokenBase, "simple test 1 gcDAI", "st1gcDAI", 18, stakeToken, reserveToken);
//  deployer.deploy(gcDAI);
};
