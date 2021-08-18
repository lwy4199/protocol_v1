// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {GunPoolContext} from "../protocol/gunpool/GunPoolContext.sol";
import {MintPolicy} from "../protocol/libraries/MintPolicy.sol";
import {SafeMath} from "../dependencies/openzeppelin/contracts/utils/math/SafeMath.sol";
import {WadRayMath} from "../protocol/gunpool/pools/aave/WadRayMath.sol";

contract MintPolicyMock {
  using SafeMath for uint256;
  using MintPolicy for GunPoolContext.PcoinReward;

  GunPoolContext.PcoinReward private _pcoinreward;
  mapping(address => GunPoolContext.RewardContext) private _rewards;
  mapping(address => uint256) private _balanceOf;
  uint256 private _supply;

  function getPcoinreward()
    external
    view
    returns (GunPoolContext.PcoinReward memory)
  {
    return _pcoinreward;
  }

  function getReward(address account)
    external
    view
    returns (GunPoolContext.RewardContext memory)
  {
    return _rewards[account];
  }

  function setPcoinreward(
    GunPoolContext.PcoinReward calldata pcoinreward
  )
    external
  {
    _supply = 0;
    _pcoinreward = GunPoolContext.PcoinReward(
                       0,
                       pcoinreward.mintMaxSupply,
                       pcoinreward.mintRateBySec,
                       block.timestamp,
                       0,
                       0
                   );
  }

  function rewardBalanceOf(uint256 timestamp)
    external
    view
    returns (uint256)
  {
    GunPoolContext.RewardContext storage reward = _rewards[msg.sender];

    uint256 mintRate = _pcoinreward.calcultionMintRate(timestamp);
    uint256 preSupply = reward.lastGpBalance.mul(reward.lastMintCapacity);
    mintRate = mintRate.add(_pcoinreward.mintCapacity);
    uint256 curSupply = reward.lastGpBalance.mul(mintRate);
    return curSupply.sub(preSupply).div(WadRayMath.ray()) + reward.rewardSupply;
  }

  event Claim(address indexed account, uint256 amount);

  function claim(uint256 timestamp)
    external
    returns (uint256)
  {
    GunPoolContext.RewardContext storage reward = _rewards[msg.sender];

    _updateMint(_pcoinreward, _supply, timestamp);
    _updateReward(reward, _pcoinreward);

    uint256 totalReward = reward.rewardSupply;
    reward.rewardSupply = 0;
    reward.lastMintCapacity = _pcoinreward.mintCapacity;
    reward.lastGpBalance = _balanceOf[msg.sender];

    emit Claim(msg.sender, totalReward);
    return totalReward;
  }

  function deposit(uint256 amount, uint256 timestamp)
    external
  {
    uint256 preBalance = _balanceOf[msg.sender];
    GunPoolContext.RewardContext storage reward = _rewards[msg.sender];
    _balanceOf[msg.sender] = preBalance.add(amount);
    _supply = _supply.add(amount);

    _updateMint(_pcoinreward, _supply, timestamp);

    if ( 0 != preBalance ) {
      _updateReward(reward, _pcoinreward);
    }
    reward.lastMintCapacity = _pcoinreward.mintCapacity;
    reward.lastGpBalance = _balanceOf[msg.sender];
  }

  function withdraw(uint256 amount, uint256 timestamp)
    external
  {
    uint256 preBalance = _balanceOf[msg.sender];
    GunPoolContext.RewardContext storage reward = _rewards[msg.sender];
    require(preBalance >= amount, "amount more than balance");
    _balanceOf[msg.sender] = preBalance.sub(amount);
    _supply = _supply.sub(amount);

    _updateMint(_pcoinreward, _supply, timestamp);
    _updateReward(reward, _pcoinreward);
    reward.lastMintCapacity = _pcoinreward.mintCapacity;
    reward.lastGpBalance = _balanceOf[msg.sender];
  }

  function _updateMint(
    GunPoolContext.PcoinReward storage pcoin,
    uint256 supply,
    uint256 timestamp
  )
    internal
  {
    if ( pcoin.mintSupply < pcoin.mintMaxSupply ) {
      uint256 mintRate = pcoin.calcultionMintRate(timestamp);
      pcoin.updateMintContext(supply, mintRate, timestamp);
    }
  }

  function _updateReward(
    GunPoolContext.RewardContext storage reward,
    GunPoolContext.PcoinReward memory pcoin
  )
    internal
  {
    uint256 preSupply = reward.lastGpBalance.mul(reward.lastMintCapacity);
    uint256 curSupply = reward.lastGpBalance.mul(pcoin.mintCapacity);
    uint256 rewardAmount = curSupply.sub(preSupply);

    if ( rewardAmount > 0 ) {
      reward.rewardSupply = reward.rewardSupply.add(rewardAmount.div(WadRayMath.ray()));
    }
  }
}
