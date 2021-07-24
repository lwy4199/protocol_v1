// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;

library Error {
  // token address is invalid
  string public constant TOKEN_ADDRESS_ZERO = '0';
  // token address is not contracts
  string public constant TOKEN_INVALID_CONTRACTS = '1';
  // token input amount is zero
  string public constant TOKEN_AMOUNT_ZERO = '3';
  // reserve is frozened
  string public constant RESERVE_FROZEN = '4';
  // reserve lptoken is zero
  string public constant RESERVE_GPTOKEN_ZERO = '5';
  // reserve is lockded
  string public constant RESERVE_LOCK = '12';
  // pool plane invalid
  string public constant POOL_PLANE_INVALID = '6';


  // gptoken must be minted by gunpool
  string public constant GPTOKEN_MINT_BE_GUNPOOL = '7';
  // gptoken mint amount is zero
  string public constant GPTOKEN_MINT_AMOUNT_ZERO = '8';
  // gptoken burn amount is zero
  string public constant GPTOKEN_BURN_AMOUNT_ZERO = '8';

  // token reserve has exist
  string public constant TOKEN_RESERVE_EXIST = '9';
  // token reserve plane input fails
  string public constant TOKEN_RESERVE_PLANE_INPUT_FAIL = '10';
  // reset token reserve has not exist
  string public constant TOKEN_RESERVE_RESET_UNEXIST = '11';


  // wmatic deposit fail
  // string public constant WMATIC_DEPOSIT_FAIL = '13';
  // wmatic withdraw fail
  // string public constant WMATIC_WITHDRAW_FAIL = '14';
  // wmatic withdraw return none
  // string public constant WMATIC_WITHDRAW_RETURN_NONE = '15';
}
