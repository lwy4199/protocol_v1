// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "../../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseERC20} from "./BaseERC20.sol";
import {Ownable} from '../../dependencies/openzeppelin/contracts/access/Ownable.sol';
import {IGunPool} from "../../interfaces/IGunPool.sol";
import {IGPToken} from "../../interfaces/IGPToken.sol";
import {IAToken} from "../gunpool/pools/aave/IAToken.sol";
import {GunPoolContext} from "../gunpool/GunPoolContext.sol";
import {Error} from "../gunpool/helpers/Error.sol";
import {WadRayMath} from "../gunpool/pools/aave/WadRayMath.sol";
import {ILendingPool} from "../gunpool/pools/aave/ILendingPool.sol";
import {DataTypes} from "../gunpool/pools/aave/DataTypes.sol";

// 通过Aave返回的Token
contract AaveGPToken is
  IGPToken,
  BaseERC20("", "" , 18),
  Ownable
{
  using WadRayMath for uint256;

  IGunPool internal _pool;
  address _correspondToken;

  modifier onlyGunPool {
    require(_msgSender() == address(_pool), Error.GPTOKEN_MINT_BE_GUNPOOL);
    _;
  }

    function initialize(
    address gunPoolAddress,
    address correspondToken,
    string calldata name,
    string calldata symbol,
    uint8 decimals
  ) external onlyOwner {
    _pool = IGunPool(gunPoolAddress);
    _correspondToken = correspondToken;
    _setName(name);
    _setSymbol(symbol);
    _setDecimals(decimals);
  }

  function mint(
    address user,
    uint256 amount
  ) external override onlyGunPool returns (bool) {
    uint256 preBalance = super.balanceOf(user);
    uint256 index = _getAaveIncome();
    uint256 amountScaled = amount.rayDiv(index);

    require(amountScaled > 0, Error.GPTOKEN_MINT_AMOUNT_ZERO);
    _mint(user, amountScaled);

    emit Mint(user, amount);

    return (preBalance == 0);
  }

  function burn(
    address user,
    uint256 amount
  )
    external
    override
  {
    uint256 index = _getAaveIncome();
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Error.GPTOKEN_BURN_AMOUNT_ZERO);

    if ( amountScaled > super.balanceOf(user) )
      amountScaled = super.balanceOf(user);
    _burn(user, amountScaled);

    emit Transfer(user, address(0), amount);
    emit Burn(user, amount);
  }

  function balanceOf(address account)
    public
    override(BaseERC20, IERC20)
    view
    returns (uint256)
  {
    uint256 index = _getAaveIncome();
    return super.balanceOf(account).rayMul(index);
  }

  function totalSupply()
    public
    override(BaseERC20, IERC20)
    view
    returns (uint256)
  {
    uint256 currentSupply = super.totalSupply();
    if ( currentSupply == 0 ) {
      return 0;
    }
    else {
      uint256 index = _getAaveIncome();
      return currentSupply.rayMul(index);
    }
  }

  function getUserNormalBalanceAndSupply(address user)
    public
    override
    view
    returns (uint256, uint256)
  {
    return (super.balanceOf(user), super.totalSupply());
  }

  function getNormalTotalSupply()
    public
    override
    view
    returns (uint256)
  {
    return super.totalSupply();
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
    ) internal override
  {
    uint256 index = _getAaveIncome();

    // uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
    // uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

    super._transfer(from, to, amount.rayDiv(index));
  }

  function _getAaveIncome()
    internal
    view
    returns (uint256)
  {
    GunPoolContext.PlaneContext memory plane =
      _pool.getPlanes(_correspondToken, GunPoolContext.PlaneType.AAVE);
    ILendingPool lendingPool = ILendingPool(plane.plane);
    return lendingPool.getReserveNormalizedIncome(_correspondToken);
  }
}
