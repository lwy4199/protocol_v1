// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;

import {GunPoolContext} from "../gunpool/GunPoolContext.sol";
import {SafeMath} from "../../dependencies/openzeppelin/contracts/math/SafeMath.sol";

library RewardPolicy {
  using SafeMath for uint256;

  function calcultionReward(
    GunPoolContext.RewardContext memory reward,
    uint256 mintSec,
    uint256 curSupply
    )
    internal
    view
    returns (uint256)
  {
    if ( reward.lastUpdatetime < block.timestamp ) {
      uint256 timeDiff = block.timestamp.sub(reward.lastUpdatetime);
      uint256 rewardAmount = mintSec.mul(timeDiff);
      uint256 lastReward = rewardAmount
                           .mul(reward.lastGPTokenBalance)
                           .div(reward.lastGPTokenSupply);
      uint256 curReward = rewardAmount
                          .mul(reward.lastGPTokenBalance)
                          .div(curSupply);
      rewardAmount = lastReward.add(curReward).div(2);
      return rewardAmount;
    }
    else {
      return 0;
    }
  }

  function updateRewardContext(
    GunPoolContext.RewardContext storage reward,
    uint256 curBalance,
    uint256 curSupply,
    uint256 totalAmount
    )
    internal
  {
    reward.lastGPTokenBalance = curBalance;
    reward.lastGPTokenSupply = curSupply;
    reward.pcoinAmount = totalAmount;
    reward.lastUpdatetime = block.timestamp;
  }
}
