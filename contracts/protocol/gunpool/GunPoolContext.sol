// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;

library GunPoolContext {
  struct ReserveData {
    // for pcoin reward
    PcoinReward pcoin;
    // PlaneType
    PlaneType pt;
    // aave plane
    AavePlane aavePlane;
    // reserve frozen flag
    bool isFrozen;
  }

  struct AavePlane {
    // aave lendingpool address
    address aaveAddress;
    // gun pool token address for mapping aave lending pool token
    address gpTokenAddress;
  }

  // pcoin reward
  struct PcoinReward {
    // the current mint supply of pcoin
    uint256 mintSupply;
    // the max mint supply of pcoin
    uint256 mintMaxSupply;
    // the mint rate in second from pcoin
    uint256 mintRateBySec;
    // the mint decay rate
    uint16  mintDecayRate;
  }

  // record the reward of account
  struct RewardContext {
    // last update reward time
    uint256 lastUpdatetime;
    // the reward amount of pcoin which has obtained but not draw by account
    uint256 pcoinAmount;
    // last gptoken balance
    uint256 lastGPTokenBalance;
    // last gptoken supply
    uint256 lastGPTokenSupply;
  }

  enum PlaneType {NONE, AAVE}

}
