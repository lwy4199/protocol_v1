// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library StakePoolContext {
    /*
    * order status:
    *     init: order will be initialized once success it will go to subscribe
    *     subscribe: user can deposit/withdraw matic anytime;
    *     migrate: user can also deposit matic before proxy get matic from stakepool to stake in ethereum
    *     locking storage: the matic of users are locked to stake in eth;
    *     claim: the user can be claim reward from this order.
    */
    enum ORDER_STATUS {INIT, SUBSCRIBE, MIGRATE, LOCKING, CLAIM, SPARE}

    /*
    * order context
    *     id: the unique number of this order identification;
    *     state: the state of this order;
    *     stateTime: the state switch time of this order;
    *     threshold: the threshold of stake;
    *        if Supply >= Threshold the order status would be changed to LOCKING_STORAGE from SUBSCRIBE
    *     period: the length of order locking storage time;
    *     proxy: who would bridge matic form layer-2 to Ethereum to delegate;
    *     pcoinReward: the reward of pcoin from this order;
    *     feeTo: the plane account who will get part of matic reward by FeePermillage;
    *     FeePermillage: base 1000.
    */
    uint16 constant FEE_PERMILLAGE_BASE = 1000;
    uint16 constant FEE_PERMILLAGE_MAX = 200;
    uint256 constant DELEGATE_AMOUNT_MIN = 10**18;
    struct Order {
        uint128 id;
        ORDER_STATUS state;
        uint256[] stateTime;
        uint256 threshold;
        uint32 period;
        address proxy;
        uint256 pcoinReward;
        address feeTo;
        uint16 feePermillage;
    }

    struct OrderInitParam {
        uint128 id;
        uint256 threshold;
        uint32  period;
        address proxy;
        uint256 pcoinReward;
        address feeTo;
        uint16  feePermillage;
    }

    /*
    * user context in the order
    *   balances: the deposit amount of every user;
    *   hasDelegate: the user has delegated in this order;
    *   totalSupply: the total supply of deposit amount;
    *   accounts: the account address of all users;
    *   pcoinReward: the reward of pcoin.
    */
    struct User {
        mapping(address => bool) delegates;
        mapping(address => uint256) balances;
        mapping(address => uint256) pcoinReward;
        uint256 totalSupply;
        address[] accounts;
    }
}