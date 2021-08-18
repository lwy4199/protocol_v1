// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library GunPoolContext {
  struct ReserveData {
    // for pcoin reward
    PcoinReward pcoin;
    // PlaneType
    PlaneType pt;
    // reserve frozen flag
    bool isFrozen;
    // lock
    bool lock;
  }

  // Plane context
  struct PlaneContext {
    // plane address
    address plane;
    // gunpool token address for plane
    address gptoken;
  }

  // pcoin reward
  struct PcoinReward {
    // the current mint supply of pcoin
    uint256 mintSupply;
    // the max mint supply of pcoin
    uint256 mintMaxSupply;
    // the mint rate in second from pcoin
    uint256 mintRateBySec;
    // the last mint time
    uint256 lastMintTime;
    // the last supply of mint token
    uint256 lastSupply;
    // the mint accumulation capacity of one unit token
    uint256 mintCapacity;
  }

  // record the reward of account
  struct RewardContext {
    // record the reward supply of pcoin which has obtained by account
    uint256 rewardSupply;
    // last mint capacity of one unit token
    uint256 lastMintCapacity;
    // last balance of gptoken
    uint256 lastGpBalance;
  }

  enum PlaneType {AAVE}

  struct PlaneInitInput {
    PlaneType pt;
    PlaneContext plane;
  }

  struct FeeContext {
    // fee account
    address account;
    // the max fee ratio is 10
    uint16  permillage;
  }
}
