const GunPool = artifacts.require("GunPool");
//const AaveGPToken = artifacts.require("AaveGPToken");

module.exports = async function (deployer) {
  await deployer.deploy(GunPool,
                       '0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889',
                       {from: '0xb1b4C08D9dBA94Af1A1a142cB87F22637B01829D', chainId: 80001});
  //await deployer.deploy(AaveGPToken,
  //                      {from: '0xb1b4C08D9dBA94Af1A1a142cB87F22637B01829D', chainId: 80001})

};
