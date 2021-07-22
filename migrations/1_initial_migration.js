const AaveGPToken = artifacts.require("AaveGPToken");
const GunpoolMock = artifacts.require("GunpoolMock");
const LoodingPoolMock = artifacts.require("LoodingPoolMock");

module.exports = async function (deployer) {
  await deployer.deploy(GunpoolMock);
  let GpMock = await GunpoolMock.deployed();
  // console.log(typeof GpMock.address);

  await deployer.deploy(LoodingPoolMock, "0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e");
  let LPMock = await LoodingPoolMock.deployed();
  // console.log(GpMock.address, LPMock.address);

  await deployer.deploy(AaveGPToken);
  let GPToken = await AaveGPToken.deployed();

  //
  await GpMock.initReserve("0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e",
                           GPToken.address,
                           LPMock.address);

  await GPToken.initialize(GpMock.address,
                           "0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e",
                           "Polylend GPUSDC",
                           "GPUSDC",
                           6);

  var name = await GPToken.name();
  console.log(name);
};
