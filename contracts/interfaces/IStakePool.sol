// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import {StakePoolContext} from "../protocol/stakepool/StakePoolContext.sol";

interface IStakePool {
    /**** function description ****/

    /**
     * @dev initOrder initializes parameters for order
     * @param orderParam the initialization parameters of order
     * Emits a {InitOrder} event.
    **/
    function initOrder(StakePoolContext.OrderInitParam calldata orderParam) external returns (uint128);

    /**
     * @dev delegate deposit matic into contract to stake
     * Emits a {Delegate} event.
    **/
    function delegate() external payable;

    /**
     * @dev undelegate withdraw matic from contract to unstake
     * @param amount the withdraw amount of user
     * Emits a {Undelegate} event.
    **/
    function undelegate(uint256 amount) external;

    /**
     * @dev lock it is migrating matic from contract to ethereum
     * Emits a {Migrate} event
    **/
    function lock() external;

    /**
    * @dev balanceOf get balance of account
    * @param account who has delegated
    **/
    function balanceOf(address account) external view returns (uint256);

    /**
    * @dev totalSupply get supply of this contract
    **/
    function totalSupply() external view returns (uint256);

    /**
     * @dev InitOrder on initOrder()
     * @param order the parameters of order
    **/
    event InitOrder(StakePoolContext.Order order);

    /**
     * @dev Delegate on delegate()
     * @param id the index of order
     * @param account who delegates matic
     * @param amount the amount of delegate matic
    **/
    event Delegate(uint128 indexed id, address indexed account, uint256 amount);

    /**
     * @dev UnDelegate on undelegate()
     * @param id the index of order
     * @param account who undelegates matic
     * @param amount the amount of undelegate matic
    **/
    event UnDelegate(uint128 indexed id, address indexed account, uint256 amount);

    /**
    * @dev Migrate on lock()
    * @param id the index of order
    * @param proxy who get matic to migrate
    * @param amount the amount of migrate matic
    **/
    event Migrate(uint128 indexed id, address indexed proxy, uint256 amount);


    /**
     * @dev StatusTransfer on status switch
     * @param id the index of order
     * @param preState the previous status
     * @param curState the current status
    **/
    event StatusTransfer(uint128 indexed id,
                         StakePoolContext.ORDER_STATUS preState,
                         StakePoolContext.ORDER_STATUS curState);

    /**
     * @dev Warn on contract exception
     * @param id the index of order
     * @param msg description exception
    **/
    event Warn(uint128 indexed id, string msg);
}