// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {GunPoolContext} from "../protocol/gunpool/GunPoolContext.sol";

/**
 * @dev Interface of the Gun Pool standard as defined in the EIP.
 */
interface IGunPool {

  /**** function description ****/

  /**
   * @dev deposit the ERC20 token
   * @param token The address of the token to deposit.(For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param amount The amount of the token to deposit.(For max: `uint256(-1)`)
   * Emits a {Deposit} event.
   **/
  function deposit(address token, uint256 amount) external;

  /**
   * @dev withdraw the ERC20 token
   * @param token The address of the token to withdraw.(For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param amount The amount of the lptoken (For max: `uint256(-1)`)
   * Returns a boolean value indicating whether the operation succeeded.
   * Emits a {Withdraw} event.
   **/
  function withdraw(address token, uint256 amount) external returns (uint256);

  /**
   * @dev deposit the mainet basis token
   * Returns a boolean value indicating whether the operation succeeded.
   * Emits a {Deposit} event.
  **/
  function depositByEth() external payable;

  /**
   * @dev withdraw the mainet basis token
   * @param amount The amount of the token to withdraw.(For max: `uint256(-1)`)
   * Returns a boolean value indicating whether the operation succeeded.
   * Emits a {Withdraw} event.
  **/
  function withdrawByEth(uint256 amount) external;

  /**
   * @dev claim from gun pool(contain: polylend token)
   * Returns amount The total amount of reward is obtained by to which is
             recalculated by pcoin
   * Emits a {Claim} event.
  **/
  function claim(address to) external returns (uint256);

  /**
   * @dev rewardBalanceOf quary pcoin rewards
   * @param user who has rewards
   * Returns balance The total amount of reward
  **/
  function rewardBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the state of the reserve in gunpool
   * @param token The address of the underlying token of the reserve
   * @return The state of the reserve in gunpool
  **/
  function getReserve(address token) external view returns (GunPoolContext.ReserveData memory);

  /**
   * @dev initReserve configure the reserve in gunpool
   * @param token The address of the underlying token of the reserve
   * @param planes the context of the plane
   * @param pcoin The reward context of polylend coin
   * Emits a {InitReserve} event.
  **/
  function initReserve(
    address token,
    GunPoolContext.PlaneInitInput[] calldata planes,
    GunPoolContext.PcoinReward calldata pcoin
  ) external;

  /**
   * @dev resetReservePcoinReward reset pcoin reward params for reserve
   * @param token The address of the underlying token of the reserve
   * @param pcoin The reward context of polylend coin
   * Emits a {ResetPcoinReward} event
  **/
  function resetPcoinReward(
    address token,
    GunPoolContext.PcoinReward calldata pcoin
  ) external;

  /**
   * @dev resetPlane reset plane for reserve
   * @param token The address of the underlying token of the reserve
   * @param planeInput the context of the plane
   * Emits a {ResetPlane} event
  **/
  function resetPlane(
    address token,
    GunPoolContext.PlaneInitInput calldata planeInput
  ) external;

  /**
   * @dev initPcoinAddress set the address of pcoin
   * @param pcoinAddress the address of pcoin who mint reward for user
   * Emits a {SetPcoinAddress} event
  **/
  function setPcoinAddress(address pcoinAddress) external;

  /**
   * @dev pause set token frozen status
   * @param token the address of reserve
   * @param frozen the status of reserve, true is frozen
   * Emits a {Pause} event
  **/
  function pause(address token, bool frozen) external;

  /**
   * @dev setFeeto set account and permillage for fee
   * @param feeTo the context of feeto
   * Emits a {SetFeeTo} event
  **/
  function setFeeto(GunPoolContext.FeeContext calldata feeTo) external;

  /**
   * @dev getPlanes get the context address of work plane
   * @param token the address of reserve
   * @param pt the type of plane
   * @return planecontext contain address of plane and gptoken
  **/
  function getPlanes(address token, GunPoolContext.PlaneType pt)
  external view returns(GunPoolContext.PlaneContext memory);

  /**
   * @dev getDepositAPY get the APY of deposited token
   * @param token the address of reserve
   * @return APY: Annual percentage yields
  **/
  function getDepositAPY(address token) external view returns(uint256);

  /**
   * @dev getDepositAccounts get acconts of deposit
   * @return Accounts: who has deposited
  **/
  function getDepositAccounts() external view returns(uint32);

  /**** event description ****/
  /**
   * @dev Emitted on deposit()
   * @param token The address of token which can be deposited in gun pool
   * @param user The address of the user who deposit token
   * @param amount The amount that the user wants to deposit
   **/
  event Deposit(address indexed token, address indexed user, uint256 amount);

  /**
   * @dev Emitted on withdraw()
   * @param token The address of token which can be deposited in gun pool
   * @param user The address of the user who obtain token
   * @param amount The amount that the user wants to withdraw
   **/
  event Withdraw(address indexed token, address indexed user, uint256 amount);

  /**
   * @dev Emitted on Claim()
   * @param from The address of user who has a opportunity to get reward from gun pool
   * @param to The address of the user who get the reward
   * @param amount The toatl amount of reward that the user(to) gets which is
            recalculated by mainet basis token
   **/
  event Claim(address indexed from, address indexed to, uint256 amount);

  /**
   * @dev Emitted on initReserve()
   * @param token the address of token who was initialized
   * @param pcoin the reward policy of pcoin
   * @param gptAddress the address pool of gptoken
   **/
  event InitReserve(address indexed token,
    GunPoolContext.PcoinReward pcoin,
    address[] gptAddress);
  /**
   * @dev Emitted on resetPcoinReward()
   * @param token the address of token who was initialized
   * @param pcoin the reward policy of pcoin
  **/
  event ResetPcoinReward(address indexed token, GunPoolContext.PcoinReward pcoin);

  /**
   * @dev Emitted on pause()
   * @param token the address of token who was initialized
   * @param frozen the status of reserve, true is frozen
  **/
  event Pause(address indexed token, bool frozen);

  /**
   * @dev Emitted on setPcoinAddress()
   * @param pcoinAddress the address of pcoin who mint reward for user
  **/
  event SetPcoinAddress(address indexed pcoinAddress);

  /**
   * @dev Emitted on resetPlane()
   * @param token The address of the underlying token of the reserve
   * @param pt the type of plane
   * @param pc the address of the plane
  **/
  event ResetPlane(address indexed token,
    GunPoolContext.PlaneType indexed pt,
    GunPoolContext.PlaneContext pc);

  /**
   * @dev Emitted on setFeeTo()
   * @param feeAccount the account of feeTo
   * @param permillage the ratio of feeTo(base 1000)
  **/
  event SetFeeto(address feeAccount, uint16 permillage);

  event Log(string msg, uint256 value);
}