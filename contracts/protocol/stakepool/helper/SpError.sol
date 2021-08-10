// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;

library SpError {
    // order does not initialize for state mismatch
    string public constant ORDER_INIT_FAIL_FOR_STATE = '0';
    // order proxy is zero address
    string public constant ORDER_PROXY_INVALID = '1';
    // order does not delegate for state mismatch
    string public constant ORDER_DELEGATE_FAIL_FOR_STATE = '2';
    // delegate amount is invalid
    string public constant DELEGATE_AMOUNT_INVALID = '3';
    // undelegate amount is zero
    string public constant DELEGATE_AMOUNT_ZERO = '4';
    // undelegate must in subscribe status
    string public constant UNDELEGATE_NOT_SUBSCRIBE = '5';
}