const AaveGPToken = artifacts.require("AaveGPToken");
const GpMock = artifacts.require("GunpoolMock");
const LpMock = artifacts.require("LoodingPoolMock");

let account_one;
let account_two;
let account_three;
let GpTokenIns;
let GpMockIns;
let LpMockIns;
let token_address = "0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e";

function sleep(ms) {
    return new Promise(resolve=>setTimeout(resolve, ms))
}

contract('AaveGPToken', async accounts => {

  beforeEach(async () => {
    GpTokenIns = await AaveGPToken.deployed();
    GpMockIns = await GpMock.deployed();
    LpMockIns = await LpMock.deployed();
    account_one = accounts[0];
    account_two = accounts[1];
    account_three = accounts[2];
    //GpMockAddress = await GpMock.at(GpMockContractIns.address);
    //LpMockAddress = await LpMock.at(LpMockContractIns.address);
    //console.log(GpMockContractIns.address);
  });

  it('init',async() => {
      const coinname = await GpTokenIns.name();
      const coinsymbol = await GpTokenIns.symbol();
      const decimals = await GpTokenIns.decimals();
      console.log(coinname);
      assert.equal(coinname, 'Polylend GPUSDC');
      assert.equal(coinsymbol, 'GPUSDC');
      assert.equal(decimals, 6);
  });

  it('mint', async() => {
      await GpMockIns.mint(GpTokenIns.address, 100000, {from: account_one});
      let balance = (await GpTokenIns.balanceOf(account_one)).toNumber();
      assert.equal(balance, 100000);
      await GpMockIns.mint(GpTokenIns.address, 200000, {from: account_one});
      balance = (await GpTokenIns.balanceOf(account_one)).toNumber();
      assert.equal(balance, 300000);
      let index_0 = (await LpMockIns.getReserveNormalizedIncome(token_address)).toNumber();

      // mock timestamp to compute APY
      let timestamp = (await LpMockIns.getLastBlockTime()).toNumber();
      timestamp = timestamp + 300;
      await LpMockIns.setCurBlockTime(timestamp);
      balance = (await GpTokenIns.balanceOf(account_one)).toNumber();
      let index_1 = (await LpMockIns.getReserveNormalizedIncome(token_address)).toNumber();
      //let timestamp = (await web3.eth.getBlock()).timestamp;
      assert.equal(balance, 300000*index_1/index_0);

      // will mint more token and compute APY continuity
      await GpMockIns.mint(GpTokenIns.address, 600000, {from: account_one});
      timestamp = (await LpMockIns.getLastBlockTime()).toNumber();
      timestamp = timestamp + 100;
      await LpMockIns.setCurBlockTime(timestamp);
      balance = (await GpTokenIns.balanceOf(account_one)).toNumber();
      let index_2 = (await LpMockIns.getReserveNormalizedIncome(token_address)).toNumber();
      assert.equal(balance, Math.floor(300000*index_2/index_0+600000*index_2/index_1));
  });

  it('transfer', async() => {
    let balance_one = (await GpTokenIns.balanceOf(account_one)).toNumber();
    await GpTokenIns.transfer(account_two, 10000, {from: account_one});
    let balance_one_1 = (await GpTokenIns.balanceOf(account_one)).toNumber();
    assert.equal(balance_one_1, balance_one-10000);
    let balance_two_0 = (await GpTokenIns.balanceOf(account_two)).toNumber();
    assert.equal(balance_two_0, 10000);

    // success
    // await GpTokenIns.transfer(account_two, 1000000, {from: account_one});
  });

  it('burn', async() => {
      balance = (await GpTokenIns.balanceOf(account_one)).toNumber();
      let timestamp = (await web3.eth.getBlock()).timestamp;
      console.log(balance, timestamp);
  });

  it('approve', async() => {

  });

  it('add mint pool', async() => {

  });

})
