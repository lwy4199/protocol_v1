// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;
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
  function depositByEth() external payable returns (bool);

  /**
   * @dev withdraw the mainet basis token
   * @param amount The amount of the token to withdraw.(For max: `uint256(-1)`)
   * Returns a boolean value indicating whether the operation succeeded.
   * Emits a {Deposit} event.
  **/
  function withdrawByEth(uint256 amount) external returns (bool);

  /**
   * @dev reward from gun pool(contain: polylend token or mainet basis token)
   * Returns amount The total amount of reward is obtained by to which is
             recalculated by mainet basis token
   * Emits a {Reward} event.
  **/
  function reward(address to) external returns (uint256);

  /**
   * @dev rewardview quary pcoin rewards
   * @param user who has rewards
   * Returns amount The total amount of reward
  **/
  function rewardView(address user) external view returns (uint256);

  /**
   * @dev Returns the state of the reserve in gunpool
   * @param token The address of the underlying token of the reserve
   * @return The state of the reserve in gunpool
  **/
  function getReserve(address token) external view returns (GunPoolContext.ReserveData memory);

  /**
   * @dev Returns the state of the reserve in gunpool
   * @param token The address of the underlying token of the reserve
   * @param pcoin The reward context of polylend coin
   * @param aavePlane the plane context of aave lending pool
   * Emits a {initReserve} event.
  **/
  function initReserve(
    address token,
    GunPoolContext.PcoinReward calldata pcoin,
    GunPoolContext.AavePlane calldata aavePlane
    ) external;

  /**
   * @dev initPcoinAddress set the address of pcoin
   * @param pcoinAddress the address of pcoin who mint reward for user
  **/
  function setPcoinAddress(address pcoinAddress) external;

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
   * @dev Emitted on reward()
   * @param from The address of user who has a opportunity to get reward from gun pool
   * @param to The address of the user who get the reward
   * @param amount The toatl amount of reward that the user(to) gets which is
            recalculated by mainet basis token
   **/
  event Reward(address indexed from, address indexed to, uint256 amount);

  /**
   * @dev Emitted on InitReserve()
   * @param token the address of token who was initialized
   * @param pcoin the reward policy of pcoin
   * @param gptokenAddresses the address pool of gptoken(aave and so on)
   **/
  event InitReserve(address indexed token,
                    GunPoolContext.PcoinReward pcoin,
                    address[] gptokenAddresses);
}
