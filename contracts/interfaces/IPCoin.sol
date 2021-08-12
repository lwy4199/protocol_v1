// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;

import {IERC20} from "../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";

/***** Polylend Coin interface *****/
interface IPCoin is IERC20 {

    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;
}