// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import {GunPoolContext} from "../protocol/gunpool/GunPoolContext.sol";
import {MintPolicy} from "../protocol/libraries/MintPolicy.sol";
import {SafeMath} from "../dependencies/openzeppelin/contracts/math/SafeMath.sol";
import {WadRayMath} from "../protocol/gunpool/pools/aave/WadRayMath.sol";

contract MintPolicyMock {
  using SafeMath for uint256;
  using MintPolicy for GunPoolContext.PcoinReward;

  GunPoolContext.PcoinReward private _pcoinreward;
  mapping(address => GunPoolContext.RewardContext) private _rewards;
  mapping(address => uint256) private _balanceOf;
  uint256 private _supply;

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

  function deposit(uint256 amount, uint256 timestamp)
    external
  {
    uint256 preBalance = _balanceOf[msg.sender];
    GunPoolContext.RewardContext storage reward = _rewards[msg.sender];
    _balanceOf[msg.sender] = preBalance.add(amount);
    _supply = _supply.add(amount);

    bool isMint = _updateMint(_pcoinreward, _supply, timestamp);

    if ( isMint ) {
      if ( 0 == preBalance ) {
        _updateReward(reward, _pcoinreward);
      }
    }
    reward.lastMintCapacity = _pcoinreward.mintCapacity;
    reward.lastGpBalance = _balanceOf[msg.sender];
  }

  function withdraw(uint256 amount, uint256 timestamp)
    external
  {
    uint256 preBalance = _balanceOf[msg.sender];
    GunPoolContext.RewardContext storage reward = _rewards[msg.sender];
  }

  function _updateMint(
    GunPoolContext.PcoinReward storage pcoin,
    uint256 supply,
    uint256 timestamp
  )
    internal
    returns (bool)
  {
    uint256 mintRate = pcoin.calcultionMintRate(timestamp);
    pcoin.updateMintContext(supply, mintRate, timestamp);
    if ( mintRate > 0 ) {
      return true;
    }
    else {
      return false;
    }
  }

  function _updateReward(
    GunPoolContext.RewardContext storage reward,
    GunPoolContext.PcoinReward memory pcoin
  )
    internal
  {
    if ( pcoin.mintSupply < pcoin.mintMaxSupply ) {
      uint256 preSupply = reward.lastGpBalance.mul(reward.lastMintCapacity);
      uint256 curSupply = reward.lastGpBalance.mul(pcoin.mintCapacity);
      uint256 rewardAmount = curSupply.sub(preSupply);

      if ( rewardAmount > 0 ) {
        reward.rewardSupply = reward.rewardSupply.add(rewardAmount);
        pcoin.mintSupply = pcoin.mintSupply.add(rewardAmount.div(WadRayMath.ray()));
      }
    }
  }
}
