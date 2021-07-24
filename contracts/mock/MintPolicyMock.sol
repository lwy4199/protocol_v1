// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import {GunPoolContext} from "../protocol/gunpool/GunPoolContext.sol";
import {MintPolicy} from "../protocol/libraries/MintPolicy.sol";

contract MintPolicyMock {
  GunPoolContext.PcoinReward private _pcoinreward;
  mapping(address => GunPoolContext.RewardContext) private _rewards;
  mapping(address => uint256) private _balanceOf;

  function setPcoinreward(
    GunPoolContext.PcoinReward calldata pcoinreward
  )
    external
  {
    _pcoinreward = GunPoolContext.PcoinReward(
                       0,
                       pcoinreward.mintMaxSupply,
                       pcoinreward.mintRateBySec,
                       block.timestamp,
                       0,
                       0
                   );
  }

  function deposit(uint256 amount)
    external
  {
    uint256 preBalance = _balanceOf[msg.sender];
    GunPoolContext.RewardContext storage reward = _rewards[msg.sender];

    if ( 0 == preBalance ) {

    }
  }


}
