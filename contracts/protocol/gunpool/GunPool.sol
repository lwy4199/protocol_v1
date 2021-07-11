// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import {IGunPool} from "../../interfaces/IGunPool.sol";
import {IGPToken} from "../../interfaces/IGPToken.sol";
import {Ownable} from '../../dependencies/openzeppelin/contracts/access/Ownable.sol';
import {GunPoolContext} from "./GunPoolContext.sol";
import {IERC20} from "../../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../../dependencies/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Address} from "../../dependencies/openzeppelin/contracts/utils/Address.sol";
import {Error} from "./helpers/Error.sol";
import {DataTypes} from "./pools/aave/DataTypes.sol";
import {ILendingPool} from "./pools/aave/ILendingPool.sol";
import {IAToken} from "./pools/aave/IAToken.sol";
import {SafeMath} from "../../dependencies/openzeppelin/contracts/math/SafeMath.sol";
import {RewardPolicy} from "../libraries/RewardPolicy.sol";


contract GunPool is IGunPool, Ownable {
  using Address for address;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using RewardPolicy for GunPoolContext.RewardContext;

  /**** data context ****/
  // pcoin address
  address internal _pcoinAddress;
  // reservers: key is token; value is resverer data
  mapping(address => GunPoolContext.ReserveData) internal _reserves;
  // rewards: key is user and token, value is reward context
  mapping(address => mapping(address => GunPoolContext.RewardContext)) internal _rewards;
  // reservers token list and count
  mapping(uint32 => address) internal _reservesList;
  uint32 internal _reservesCount;

  /**** modifier ****/
  modifier tokenValid(address token, uint256 amount) {
    require(token != address(0), Error.TOKEN_ADDRESS_ZERO);
    require(token.isContract(), Error.TOKEN_INVALID_CONTRACTS);
    require(amount > 0, Error.TOKEN_AMOUNT_ZERO);
    _;
  }

  /**** constructor funcion ****/
  constructor () public {
    _reservesCount = 0;
  }

  /**** public function ****/
  function initReserve(
    address token,
    GunPoolContext.PcoinReward calldata pcoin,
    GunPoolContext.AavePlane calldata aavePlane
    ) external override onlyOwner
  {
    require(token != address(0), Error.TOKEN_ADDRESS_ZERO);
    require(token.isContract(), Error.TOKEN_INVALID_CONTRACTS);

    for (uint32 i = 0; i < _reservesCount; i++) {
      require(token != _reservesList[i], Error.TOKEN_RESERVE_EXIST);
    }

    GunPoolContext.ReserveData storage reserve = _reserves[token];
    reserve.pt = GunPoolContext.PlaneType.AAVE;
    reserve.pcoin = GunPoolContext.PcoinReward(0,
                                               pcoin.mintMaxSupply,
                                               pcoin.mintRateBySec,
                                               pcoin.mintDecayRate);
    reserve.aavePlane = GunPoolContext.AavePlane(aavePlane.aaveAddress,
                                                 aavePlane.gpTokenAddress);
    reserve.isFrozen = false;

    _reservesList[_reservesCount] = token;
    _reservesCount++;

    address[] memory gptokenAddresses
      = new address[](1);

    gptokenAddresses[0] = aavePlane.gpTokenAddress;
    emit InitReserve(token, pcoin, gptokenAddresses);
  }

  function setPcoinAddress(address pcoinAddress)
    external
    override
    onlyOwner
  {
    _pcoinAddress = pcoinAddress;
  }

  /*
  * user who deposit by polylend gunpool will get gptoken and obtain pcoin reward
  */
  function deposit(
    address token,
    uint256 amount
  ) external override tokenValid(token, amount) {
    GunPoolContext.ReserveData storage reserve = _reserves[token];
    _reserveValidate(reserve);
    bool isFirst = false;
    IGPToken gpToken;
    uint256 gpTokenOldTotalSupply = 0;

    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    if ( reserve.pt == GunPoolContext.PlaneType.AAVE ) {
      gpToken = IGPToken(reserve.aavePlane.gpTokenAddress);
      gpTokenOldTotalSupply = gpToken.totalSupply();
      isFirst = _aaveDeposit(token,
                             reserve.aavePlane.aaveAddress,
                             gpToken,
                             msg.sender,
                             amount);
    }
    else {
      require(false, Error.POOL_PLANE_INVALID);
    }

    GunPoolContext.RewardContext storage reward = _rewards[msg.sender][token];
    if ( isFirst ) {
      reward.lastUpdatetime = block.timestamp;
      reward.pcoinAmount = 0;
      (reward.lastGPTokenBalance, reward.lastGPTokenSupply) =
        gpToken.getUserNormalBalanceAndSupply(msg.sender);
    }
    else {
      _updateReward(reward,
                    reserve.pcoin,
                    gpToken,
                    gpTokenOldTotalSupply,
                    msg.sender);
    }

    emit Deposit(token, msg.sender, amount);
  }

  function withdraw(
    address token,
    uint256 amount
  ) external override tokenValid(token, amount) returns (uint256) {
    GunPoolContext.ReserveData storage reserve = _reserves[token];
    _reserveValidate(reserve);
    uint256 amountWithdraw = 0;
    IGPToken gpToken;
    uint256 gpTokenOldTotalSupply = 0;

    if ( reserve.pt == GunPoolContext.PlaneType.AAVE ) {
      gpToken = IGPToken(reserve.aavePlane.gpTokenAddress);
      gpTokenOldTotalSupply = gpToken.totalSupply();
      amountWithdraw= _aaveWithdraw(token,
                                    reserve.aavePlane.aaveAddress,
                                    gpToken,
                                    msg.sender,
                                    amount);
    }
    else {
      require(false, Error.POOL_PLANE_INVALID);
    }

    GunPoolContext.RewardContext storage reward = _rewards[msg.sender][token];
    _updateReward(reward, reserve.pcoin, gpToken, gpTokenOldTotalSupply, msg.sender);

    // to reward auto for msg.sender
    if ( gpToken.balanceOf(msg.sender) == 0 ) {
      // _reward(reward, reserve.pcoin, msg.sender);
      uint256 totalReward = reward.pcoinAmount;
      _updateRewardContext(reward, gpToken, msg.sender, 0);
      if ( (_pcoinAddress != address(0)) && (totalReward > 0) ) {
        IERC20(_pcoinAddress).safeTransfer(msg.sender, totalReward);
      }
    }

    emit Withdraw(token, msg.sender, amountWithdraw);
    return amountWithdraw;
  }

  function depositByEth()
    external payable override returns (bool) {
    return true;
  }

  function withdrawByEth(
    uint256 amount
  ) external override returns (bool) {
    return true;
  }

  function reward(
    address to
  ) external override returns (uint256) {
    uint256 totalReward = 0;
    GunPoolContext.ReserveData storage reserve;
    GunPoolContext.RewardContext storage rewardContext;
    IGPToken gpToken;
    uint256 gpTokenOldTotalSupply = 0;
    address token = address(0);

    for ( uint32 i = 0; i < _reservesCount; i++ ) {
      token = _reservesList[i];
      reserve = _reserves[token];
      rewardContext = _rewards[msg.sender][token];

      if ( reserve.pt == GunPoolContext.PlaneType.AAVE ) {
        gpToken = IGPToken(reserve.aavePlane.gpTokenAddress);
        gpTokenOldTotalSupply = gpToken.totalSupply();

        _updateReward(rewardContext, reserve.pcoin, gpToken, gpTokenOldTotalSupply, msg.sender);
        totalReward = totalReward + rewardContext.pcoinAmount;
        _updateRewardContext(rewardContext, gpToken, msg.sender, 0);
      }
    }

    if ( (_pcoinAddress != address(0)) && (totalReward > 0) ) {
      IERC20(_pcoinAddress).safeTransfer(to, totalReward);
    }
  }

  function getReserve(address token)
    external
    view
    override
    returns (GunPoolContext.ReserveData memory)
  {
    return _reserves[token];
  }

  function rewardView(address user)
    external
    view
    override
    returns (uint256 amount)
  {
    GunPoolContext.ReserveData memory reserve;
    GunPoolContext.RewardContext memory rewardContext;
    IGPToken gpToken;
    uint256 gpTokenOldTotalSupply = 0;
    address token = address(0);
    uint256 totalRewardAmount = 0;

    for ( uint32 i = 0; i < _reservesCount; i++ ) {
      token = _reservesList[i];
      reserve = _reserves[token];
      rewardContext = _rewards[user][token];

      if ( reserve.pt == GunPoolContext.PlaneType.AAVE ) {
        gpToken = IGPToken(reserve.aavePlane.gpTokenAddress);
        gpTokenOldTotalSupply = gpToken.totalSupply();

        if ( reserve.pcoin.mintSupply < reserve.pcoin.mintMaxSupply ) {
          uint256 rewardAmount =
            rewardContext.calcultionReward(
              reserve.pcoin.mintRateBySec,
              gpTokenOldTotalSupply
            );
          totalRewardAmount += ( rewardAmount + rewardContext.pcoinAmount);
        }
        else {
          totalRewardAmount += rewardContext.pcoinAmount;
        }
      }
    }

    return totalRewardAmount;
  }

  /**** internal function ****/
  function _reserveValidate(GunPoolContext.ReserveData storage reserve) internal view {
    require(!(reserve.isFrozen), Error.RESERVE_FROZEN);
    require(reserve.aavePlane.gpTokenAddress != address(0), Error.RESERVE_GPTOKEN_ZERO);
  }

  function _aaveDeposit(
    address token,
    address lendingPoolAddress,
    IGPToken gpToken,
    address user,
    uint256 amount
    ) internal returns (bool) {
      ILendingPool lendingPool = ILendingPool(lendingPoolAddress);
      lendingPool.deposit(token, amount, address(this), 0);
      return gpToken.mint(user, amount);
  }

  function _aaveWithdraw(
    address token,
    address lendingPoolAddress,
    IGPToken gpToken,
    address user,
    uint256 amount
    ) internal returns (uint256) {
      ILendingPool lendingPool = ILendingPool(lendingPoolAddress);
      uint256 amountToWithdraw = amount;
      uint256 gpBalance = gpToken.balanceOf(user);

      if ( (amount == type(uint256).max) || (amount > gpBalance) )
        amountToWithdraw = gpBalance;

      gpToken.burn(user, amountToWithdraw);
      // todo receive a part of coin for self user
      lendingPool.withdraw(token, amountToWithdraw, user);
      return amountToWithdraw;
  }

  function _updateReward(
    GunPoolContext.RewardContext storage rewardContext,
    GunPoolContext.PcoinReward storage pcoin,
    IGPToken gptoken,
    uint256 gptolenOldTotalSupply,
    address user
    ) internal
  {
    if ( pcoin.mintSupply < pcoin.mintMaxSupply ) {
      uint256 rewardAmount =
        rewardContext.calcultionReward(
          pcoin.mintRateBySec,
          gptolenOldTotalSupply
        );

      if ( rewardAmount > 0 ) {
        _updateRewardContext(rewardContext, gptoken, user, rewardAmount);
        pcoin.mintSupply.add(rewardAmount);
      }
    }
  }

  function _updateRewardContext(
    GunPoolContext.RewardContext storage rewardContext,
    IGPToken gptoken,
    address user,
    uint256 rewardAmount
    )
    internal
  {
    (uint256 gpTokenBalance, uint256 gpTokenSupply) =
      gptoken.getUserNormalBalanceAndSupply(user);
    rewardContext.updateRewardContext(
      gpTokenBalance,
      gpTokenSupply,
      rewardContext.pcoinAmount.add(rewardAmount)
    );
  }
}
