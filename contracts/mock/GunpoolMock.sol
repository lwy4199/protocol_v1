// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {GunPoolContext} from "../protocol/gunpool/GunPoolContext.sol";
import {IGPToken} from "../interfaces/IGPToken.sol";

contract GunpoolMock {

  mapping (address => GunPoolContext.ReserveData) internal _reserves;
  mapping (address => mapping(GunPoolContext.PlaneType => GunPoolContext.PlaneContext)) internal _planes;

  function initReserve(
    address token,
    address gpAddress,
    address lendpoolAddress
  )
    external
  {
    _reserves[token].pt = GunPoolContext.PlaneType.AAVE;
    _planes[token][GunPoolContext.PlaneType.AAVE].gptoken = gpAddress;
    _planes[token][GunPoolContext.PlaneType.AAVE].plane = lendpoolAddress;
  }

  function getPlanes(address token, GunPoolContext.PlaneType pt)
    external
    view
    returns (GunPoolContext.PlaneContext memory)
  {
    return _planes[token][pt];
  }

  function mint(
    address gpToken,
    uint256 amount
  )
    external returns(bool)
  {
    return IGPToken(gpToken).mint(msg.sender, amount);
  }

  function burn(
    address gpToken,
    uint256 amount
  )
    external
  {
    IGPToken(gpToken).burn(msg.sender, amount);
  }

  function balanceOf(
    address gpToken,
    address account
  )
    external
    view
    returns (uint256)
  {
    return IGPToken(gpToken).balanceOf(account);
  }

}
