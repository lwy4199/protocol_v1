const MintPolicyMock = artifacts.require("MintPolicyMock");

let account_one;
let account_two;
let account_three;
let MpMockIns;
let timestamp;

contract('MintPolicyMock', async accounts => {
  beforeEach(async () => {
    MpMockIns = await MintPolicyMock.deployed();
    account_one = accounts[0];
    account_two = accounts[1];
    account_three = accounts[2];
    //GpMockAddress = await GpMock.at(GpMockContractIns.address);
    //LpMockAddress = await LpMock.at(LpMockContractIns.address);
    //console.log(GpMockContractIns.address);
    timestamp = (await web3.eth.getBlock()).timestamp;
  });

  it('init', async() => {
    const pcoin = await MpMockIns.getPcoinreward();
    console.log(pcoin);
  });

  it('deposit-withdraw', async() => {
    await MpMockIns.deposit(1000, timestamp+100, {from: account_one});
    const pcoin_0 = await MpMockIns.getPcoinreward();
    const reward_0 = await MpMockIns.getReward(account_one);
    //console.log(pcoin_0, reward_0);

    await MpMockIns.deposit(1000, timestamp+200, {from: account_one});
    const pcoin_1 = await MpMockIns.getPcoinreward();
    const reward_1 = await MpMockIns.getReward(account_one);
    assert.equal(pcoin_1.mintSupply, reward_1.rewardSupply);
    assert.equal(reward_1.rewardSupply, 100*100);

    const claim_0 = (await MpMockIns.claim(timestamp+300, {from: account_one}));
    const pcoin_2 = await MpMockIns.getPcoinreward();
    const reward_2 = await MpMockIns.getReward(account_one);
    assert.equal(reward_2.rewardSupply, 0);
    assert.equal(claim_0.logs[0]['args']['amount'].toNumber(), 100*200);
    assert.equal(pcoin_2.mintSupply, 100*200);
    //console.log(pcoin_2, reward_2, claim_0.logs[0]['args']['amount'].toNumber());

    const claim_1 = (await MpMockIns.claim(timestamp+400, {from: account_one}));
    assert.equal(claim_1.logs[0]['args']['amount'].toNumber(), 100*100);
    const pcoin_3 = await MpMockIns.getPcoinreward();
    const reward_3 = await MpMockIns.getReward(account_one);
    assert.equal(pcoin_3.mintSupply, 100*300);
    // console.log(pcoin_3, reward_3);

    await MpMockIns.withdraw(2000, timestamp+500, {from: account_one});
    const pcoin_4 = await MpMockIns.getPcoinreward();
    const reward_4 = await MpMockIns.getReward(account_one);
    assert.equal(reward_4.rewardSupply, 100*100);
    assert.equal(pcoin_4.mintSupply, 100*400);
    console.log(pcoin_4, reward_4);
  });

  it('multiple-minter', async() => {
    await MpMockIns.deposit(2000, timestamp+600, {from: account_one});
    await MpMockIns.deposit(1000, timestamp+700, {from: account_two});
    var pcoin_0 = await MpMockIns.getPcoinreward();
    var reward_one_0 = await MpMockIns.getReward(account_one);
    var reward_two_0 = await MpMockIns.getReward(account_two);
    // console.log(pcoin_0, reward_one_0, reward_two_0);
    assert.equal(pcoin_0.mintSupply, 100*500);
    assert.equal(reward_one_0.rewardSupply, 100*100);
    assert.equal(reward_two_0.rewardSupply, 0);

    await MpMockIns.deposit(1000, timestamp+800, {from: account_two});
    var pcoin_1 = await MpMockIns.getPcoinreward();
    var reward_one_1 = await MpMockIns.getReward(account_one);
    var reward_two_1 = await MpMockIns.getReward(account_two);
    assert.equal(pcoin_1.mintSupply, 59999);
    console.log(pcoin_1, reward_one_1, reward_two_1);

    var rewardBalanceOf_one = (await MpMockIns.rewardBalanceOf(timestamp+800, {from: account_one})).toNumber();
    assert.equal(rewardBalanceOf_one, 26666);
    var rewardBalanceOf_two = (await MpMockIns.rewardBalanceOf(timestamp+800, {from: account_two})).toNumber();
    assert.equal(rewardBalanceOf_two, 3333);

    rewardBalanceOf_one = (await MpMockIns.rewardBalanceOf(timestamp+900, {from: account_one})).toNumber();
    rewardBalanceOf_two = (await MpMockIns.rewardBalanceOf(timestamp+900, {from: account_two})).toNumber();
    assert.equal(rewardBalanceOf_one, 26666+5000);
    assert.equal(rewardBalanceOf_two, 3333+5000);
  });

  it('stop-mint', async() => {
    await MpMockIns.withdraw(2000, timestamp+20000002000, {from: account_two});
    var rewardBalanceOf_one = (await MpMockIns.rewardBalanceOf(timestamp+20000002000, {from: account_one})).toNumber();
    var pcoin_0 = await MpMockIns.getPcoinreward();
    console.log(pcoin_0, rewardBalanceOf_one);
    var claim_one_0 = (await MpMockIns.claim(timestamp+20000002000, {from: account_one}));
    console.log(claim_one_0.logs[0]['args']['amount'].toNumber());
  });
})
