// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;

import {GunPoolContext} from "../gunpool/GunPoolContext.sol";
import {SafeMath} from "../../dependencies/openzeppelin/contracts/math/SafeMath.sol";
import {WadRayMath} from "../gunpool/pools/aave/WadRayMath.sol";

library MintPolicy {
  using SafeMath for uint256;
  using WadRayMath for uint256;

  function calcultionMintRate(
    GunPoolContext.PcoinReward memory pcoin,
    uint256 timestamp
  )
    internal
    pure
    returns (uint256)
  {
    if ( (pcoin.lastMintTime < timestamp) && (pcoin.lastSupply > 0) ) {
      uint256 timeDiff = timestamp.sub(pcoin.lastMintTime);
      uint256 mintRate = pcoin.mintRateBySec.mul(timeDiff);
      mintRate = mintRate.mul(WadRayMath.ray());
      mintRate = mintRate.div(pcoin.lastSupply);
      return mintRate;
    }
    else {
      return 0;
    }
  }

  function updateMintContext(
    GunPoolContext.PcoinReward storage pcoin,
    uint256 supply,
    uint256 mintRate,
    uint256 timestamp
    )
    internal
  {
    pcoin.mintSupply = pcoin.mintSupply.add(pcoin.lastSupply.mul(mintRate).div(WadRayMath.ray()));
    pcoin.mintCapacity = pcoin.mintCapacity.add(mintRate);
    pcoin.lastMintTime = timestamp;
    pcoin.lastSupply = supply;
  }
}
