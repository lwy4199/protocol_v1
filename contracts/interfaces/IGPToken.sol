// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;

import {IERC20} from "../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";

/***** GP Token interface *****/
interface IGPToken is IERC20 {

  /**
   * @dev mint `amount` gpToken to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * return `true` who mint gpToken first
  **/
  function mint(address user, uint256 amount) external returns (bool);

  /**
   * @dev burns gpTokens from `user` and sends the equivalent amount of underlying to `user`
   * @param user The owner of the lpTokens, getting them burned
   * @param amount The amount being burned
  **/
  function burn(address user, uint256 amount) external;

  /**
   * @dev getUserNormalBalanceAndSupply Normal gpTokens balance from `user` and total supply of gptoken
   * @param user The owner of the gpToken
   * return: the Normal gptoken balance of user and the Normal total supply of gptoken
  **/
  function getUserNormalBalanceAndSupply(address user) external view returns(uint256, uint256);

  /**
   * @dev getNormalTotalSupply the Normal total supply of gptoken
   * return: the Normal total supply of gptoken
  **/
  function getNormalTotalSupply() external view returns(uint256);

  /**
  * @dev Emitted after the mint action
  * @param user The address receiving the lpToken
  * @param amount The amount of tokens getting minted
  * Emits a {mint} event.
  **/
  event Mint(address indexed user, uint256 amount);

  /**
   * @dev Emitted after lpTokens are burned
   * @param user The owner of the lpTokens, getting them burned
   * @param amount The amount being burned
   * Emits a {burn} event
  **/
  event Burn(address indexed user, uint256 amount);
}
