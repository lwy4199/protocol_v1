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
import {MintPolicy} from "../libraries/MintPolicy.sol";
import {IWETH} from "../../dependencies/misc/IWETH.sol";
import {WadRayMath} from "./pools/aave/WadRayMath.sol";
import {IPCoin} from "../../interfaces/IPCoin.sol";

contract GunPool is IGunPool, Ownable {
  using Address for address;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using MintPolicy for GunPoolContext.PcoinReward;

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
  // IWETH instance
  IWETH internal immutable _IWETH;
  // gptoken mapping: key is token and plane type, value is gptoken address
  mapping (address => mapping(GunPoolContext.PlaneType => GunPoolContext.PlaneContext)) internal _planes;
  // fee account
  GunPoolContext.FeeContext _feeTo;
  // the count of deposit account
  uint32 _depositAccounts;

  /**** modifier ****/
  modifier tokenValid(address token, uint256 amount) {
    require(token != address(0), Error.TOKEN_ADDRESS_ZERO);
    require(token.isContract(), Error.TOKEN_INVALID_CONTRACTS);
    require(amount > 0, Error.TOKEN_AMOUNT_ZERO);
    _;
  }

  /**** constructor funcion ****/
  constructor (address weth) public {
    _reservesCount = 0;
    _IWETH = IWETH(weth);
    _feeTo.account = address(0);
    _feeTo.permillage = 0;
    _depositAccounts = 0;
  }

  /**** public function ****/
  function initReserve(
    address token,
    GunPoolContext.PlaneInitInput[] calldata planes,
    GunPoolContext.PcoinReward calldata pcoin
  )
    external
    override
    onlyOwner
  {
    require(token != address(0), Error.TOKEN_ADDRESS_ZERO);
    require(token.isContract(), Error.TOKEN_INVALID_CONTRACTS);

    for (uint32 i = 0; i < _reservesCount; i++) {
      require(token != _reservesList[i], Error.TOKEN_RESERVE_EXIST);
    }

    GunPoolContext.ReserveData storage reserve = _reserves[token];
    reserve.pcoin = GunPoolContext.PcoinReward(0,
      pcoin.mintMaxSupply,
      pcoin.mintRateBySec,
      block.timestamp,
      0,
      0);
    reserve.pt = GunPoolContext.PlaneType.AAVE;
    reserve.isFrozen = false;
    reserve.lock = false;

    address[] memory gptoken = new address[](planes.length);
    uint256 insertNums = 0;

    for ( uint256 j = 0; j < planes.length; j++ ) {
      if ( planes[j].pt == GunPoolContext.PlaneType.AAVE ) {
        _planes[token][planes[j].pt] =
        GunPoolContext.PlaneContext(
          planes[j].plane.plane,
          planes[j].plane.gptoken
        );
        insertNums += 1;
        gptoken[j] = planes[j].plane.gptoken;
        _authorizeAAVEPlane(token, planes[j].plane.plane);
      }
    }

    require(insertNums > 0, Error.TOKEN_RESERVE_PLANE_INPUT_FAIL);
    _reservesList[_reservesCount] = token;
    _reservesCount++;

    emit InitReserve(token, pcoin, gptoken);
  }

  function resetPcoinReward(
    address token,
    GunPoolContext.PcoinReward calldata pcoin
  )
    external
    override
    onlyOwner
  {
    bool isExist = false;
    for (uint32 i = 0; i < _reservesCount; i++) {
      if ( token == _reservesList[i] ) {
        isExist = true;
        break;
      }
    }
    require(isExist, Error.TOKEN_RESERVE_RESET_UNEXIST);

    GunPoolContext.ReserveData storage reserve = _reserves[token];
    reserve.pcoin.mintMaxSupply = pcoin.mintMaxSupply;
    reserve.pcoin.mintRateBySec = pcoin.mintRateBySec;

    emit ResetPcoinReward(token, pcoin);
  }

  function resetPlane(
    address token,
    GunPoolContext.PlaneInitInput calldata planeInput
  )
    external
    override
    onlyOwner
  {
    bool isExist = false;
    for (uint32 i = 0; i < _reservesCount; i++) {
      if ( token == _reservesList[i] ) {
        isExist = true;
        break;
      }
    }
    require(isExist, Error.TOKEN_RESERVE_RESET_UNEXIST);

    GunPoolContext.PlaneContext storage planeContext = _planes[token][planeInput.pt];
    planeContext.plane = planeInput.plane.plane;
    planeContext.gptoken = planeInput.plane.gptoken;

    if ( planeInput.pt == GunPoolContext.PlaneType.AAVE ) {
      _authorizeAAVEPlane(token, planeContext.plane);
    }

    emit ResetPlane(token, planeInput.pt, planeInput.plane);
  }

  function pause(address token, bool frozen)
    external
    override
    onlyOwner
  {
    GunPoolContext.ReserveData storage reserve = _reserves[token];
    reserve.isFrozen = frozen;
    emit Pause(token, frozen);
  }

  function setPcoinAddress(address pcoinAddress)
    external
    override
    onlyOwner
  {
    _pcoinAddress = pcoinAddress;

    emit SetPcoinAddress(pcoinAddress);
  }

  function setFeeto(GunPoolContext.FeeContext calldata feeTo)
    external
    override
    onlyOwner
  {
    uint16 permillage = feeTo.permillage;
    if ( permillage > 10 ) {
      permillage = 10;
    }
    _feeTo = GunPoolContext.FeeContext(feeTo.account, permillage);
    emit SetFeeto(feeTo.account, permillage);
  }

  function getDepositAPY(address token)
    external
    override
    view
    returns(uint256)
  {
    GunPoolContext.ReserveData memory reserve = _reserves[token];
    if ( reserve.pt == GunPoolContext.PlaneType.AAVE ) {
      GunPoolContext.PlaneContext memory plane = _planes[token][reserve.pt];
      ILendingPool lendingPool = ILendingPool(plane.plane);
      DataTypes.ReserveData memory lpReserve = lendingPool.getReserveData(token);
      return lpReserve.currentLiquidityRate;
    }
    else {
      return 0;
    }
  }

  function getDepositAccounts()
    external
    override
    view
    returns(uint32)
  {
    return _depositAccounts;
  }

  /*
  * user who deposit by polylend gunpool will get gptoken and obtain pcoin reward
  */
  function deposit(
    address token,
    uint256 amount
  )
    external
    override
    tokenValid(token, amount)
  {
    _deposit(token, amount);
  }

  function _deposit(
    address token,
    uint256 amount
  )
    internal
  {
    GunPoolContext.ReserveData storage reserve = _reserves[token];
    _reserveValidate(reserve);
    bool isFirst = false;
    IGPToken gpToken;
    uint256 gpMASupply = 0;
    uint256 gpMABalance = 0;
    reserve.lock = true;

    if ( token != address(_IWETH) ) {
      IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    if ( reserve.pt == GunPoolContext.PlaneType.AAVE ) {
      GunPoolContext.PlaneContext memory plane = _planes[token][reserve.pt];
      gpToken = IGPToken(plane.gptoken);
      isFirst = _aaveDeposit(token,
        plane.plane,
        gpToken,
        msg.sender,
        amount);
      gpMABalance = gpToken.balanceOf(msg.sender);
      gpMASupply = gpToken.totalSupply();
    }
    else {
      require(false, Error.POOL_PLANE_INVALID);
    }

    _updateMint(reserve.pcoin, gpMASupply);
    GunPoolContext.RewardContext storage reward = _rewards[msg.sender][token];
    if ( !isFirst ) {
      _updateReward(reward, reserve.pcoin);
    }
    reward.lastMintCapacity = reserve.pcoin.mintCapacity;
    reward.lastGpBalance = gpMABalance;

    if ( isFirst ) {
      _depositAccounts = _depositAccounts + 1;
    }

    reserve.lock = false;
    emit Deposit(token, msg.sender, amount);
  }

  /*
  * we will convert the ratio between gptoken and input token
  */
  function withdraw(
    address token,
    uint256 amount
  ) external override tokenValid(token, amount) returns (uint256) {
    return _withdraw(token, amount);
  }

  function _withdraw(
    address token,
    uint256 amount
  )
    internal
    returns (uint256)
  {
    GunPoolContext.ReserveData storage reserve = _reserves[token];
    _reserveValidate(reserve);
    uint256 amountWithdraw = 0;
    IGPToken gpToken;
    uint256 gpMASupply = 0;
    uint256 gpMABalance = 0;
    reserve.lock = true;

    if ( reserve.pt == GunPoolContext.PlaneType.AAVE ) {
      GunPoolContext.PlaneContext memory plane = _planes[token][reserve.pt];
      gpToken = IGPToken(plane.gptoken);
      amountWithdraw = _aaveWithdraw(token,
        plane.plane,
        gpToken,
        msg.sender,
        amount);
      gpMASupply = gpToken.totalSupply();
      gpMABalance = gpToken.balanceOf(msg.sender);
    }
    else {
      require(false, Error.POOL_PLANE_INVALID);
    }

    _updateMint(reserve.pcoin, gpMASupply);
    GunPoolContext.RewardContext storage reward = _rewards[msg.sender][token];
    _updateReward(reward, reserve.pcoin);
    reward.lastMintCapacity = reserve.pcoin.mintCapacity;
    reward.lastGpBalance = gpMABalance;
    if ( gpMABalance == 0 && _depositAccounts > 0 ) {
      _depositAccounts = _depositAccounts - 1;
    }

    _claim(msg.sender);
    emit Withdraw(token, msg.sender, amountWithdraw);
    reserve.lock = false;
    return amountWithdraw;
  }

  function depositByEth()
    external payable override
  {
    uint256 amount = msg.value;
    _IWETH.deposit{value: msg.value}();
    _deposit(address(_IWETH), amount);
    //IGunPool pool = IGunPool(address(this));
    //bytes memory data = abi.encodeWithSelector(pool.deposit.selector, address(_IWETH), amount);
    //(bool success, ) = address(this).delegatecall(data);
    //require(success, Error.WMATIC_DEPOSIT_FAIL);
  }

  function withdrawByEth(uint256 amount)
    external override
  {
    //IGunPool pool = IGunPool(address(this));
    //bytes memory data = abi.encodeWithSelector(pool.withdraw.selector, address(_IWETH), amount);
    //(bool success, bytes memory returndata) = address(this).delegatecall(data);
    //require(success, Error.WMATIC_WITHDRAW_FAIL);
    //require(returndata.length > 0, Error.WMATIC_WITHDRAW_RETURN_NONE);
    //uint256 amountWithdraw = abi.decode(returndata, (uint256));
    //uint256 amountWithdraw = this.withdraw(address(_IWETH), amount);
    uint256 amountWithdraw = _withdraw(address(_IWETH), amount);
    _IWETH.withdraw(amountWithdraw);
    _safeTransferETH(msg.sender, amountWithdraw);
  }

  function claim(address to)
    external
    override
    returns (uint256)
  {
    return _claim(to);
  }

  function getReserve(address token)
    external
    view
    override
    returns (GunPoolContext.ReserveData memory)
  {
    return _reserves[token];
  }

  function getPlanes(address token, GunPoolContext.PlaneType pt)
    external
    view
    override
    returns(GunPoolContext.PlaneContext memory)
  {
    return _planes[token][pt];
  }

  function rewardBalanceOf(address user)
    external
    view
    override
    returns (uint256 amount)
  {
    GunPoolContext.ReserveData memory reserve;
    GunPoolContext.RewardContext memory reward;
    address token = address(0);
    uint256 rewardBalance = 0;
    uint256 timestamp = block.timestamp;

    for ( uint32 i = 0; i < _reservesCount; i++ ) {
      token = _reservesList[i];
      reserve = _reserves[token];
      reward = _rewards[user][token];

      uint256 mintRate = reserve.pcoin.calcultionMintRate(timestamp);
      uint256 preSupply = reward.lastGpBalance.mul(reward.lastMintCapacity);
      mintRate = mintRate.add(reserve.pcoin.mintCapacity);
      uint256 curSupply = reward.lastGpBalance.mul(mintRate);
      uint256 rewardAmount = curSupply.sub(preSupply).div(WadRayMath.ray());
      rewardAmount = rewardAmount.add(reward.rewardSupply);
      rewardBalance = rewardBalance.add(rewardAmount);
    }

    return rewardBalance;
  }

  /**** internal function ****/
  function _reserveValidate(GunPoolContext.ReserveData storage reserve) internal view {
    require(!(reserve.isFrozen), Error.RESERVE_FROZEN);
    require(!(reserve.lock), Error.RESERVE_LOCK);
    //require(reserve.aavePlane.gpTokenAddress != address(0), Error.RESERVE_GPTOKEN_ZERO);
  }

  function _aaveDeposit(
    address token,
    address lendingPoolAddress,
    IGPToken gpToken,
    address user,
    uint256 amount
  )
    internal
    returns (bool)
  {
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
  )
    internal
    returns (uint256)
  {
    ILendingPool lendingPool = ILendingPool(lendingPoolAddress);
    uint256 amountToWithdraw = amount;
    uint256 gpBalance = gpToken.balanceOf(user);

    if ( (amount == type(uint256).max) || (amount > gpBalance) ) {
      amountToWithdraw = gpBalance;
    }
    emit Log("burn withdraw", amountToWithdraw);
    gpToken.burn(user, amountToWithdraw);

    if ( token == address(_IWETH) ) {
      lendingPool.withdraw(token, amountToWithdraw, address(this));
    }
    else {
      lendingPool.withdraw(token, amountToWithdraw, user);
    }

    if ( _feeTo.account != address(0) && _feeTo.permillage > 0 ) {
      uint256 fee = _feeTo.permillage;
      fee = amountToWithdraw.mul(fee).div(1000);
      amountToWithdraw = amountToWithdraw.sub(fee);
      if ( token != address(_IWETH) ) {
        IERC20(token).safeTransferFrom(user, address(this), fee);
      }
    }

    return amountToWithdraw;
  }

  function _claim(address to)
    internal
    returns (uint256)
  {
    uint256 totalReward = 0;
    GunPoolContext.ReserveData storage reserve;
    GunPoolContext.RewardContext storage reward;
    IGPToken gpToken;
    address token = address(0);

    for ( uint32 i = 0; i < _reservesCount; i++ ) {
      token = _reservesList[i];
      reserve = _reserves[token];
      reward = _rewards[msg.sender][token];

      if ( reserve.pt == GunPoolContext.PlaneType.AAVE ) {
        GunPoolContext.PlaneContext memory plane = _planes[token][reserve.pt];
        gpToken = IGPToken(plane.gptoken);
        _updateMint(reserve.pcoin, gpToken.totalSupply());
        _updateReward(reward, reserve.pcoin);
        totalReward = totalReward.add(reward.rewardSupply);
        reward.rewardSupply = 0;
        reward.lastMintCapacity = reserve.pcoin.mintCapacity;
        reward.lastGpBalance = gpToken.balanceOf(msg.sender);
      }
    }

    if ( (_pcoinAddress != address(0)) && (totalReward > 0) ) {
      //      IERC20(_pcoinAddress).safeTransfer(to, totalReward);
      IPCoin(_pcoinAddress).mint(to, totalReward);
      emit Claim(msg.sender, to, totalReward);
      return totalReward;
    }
    else {
      return 0;
    }
  }

  function _updateMint(
    GunPoolContext.PcoinReward storage pcoin,
    uint256 supply
  )
    internal
  {
    if ( pcoin.mintSupply < pcoin.mintMaxSupply ) {
      uint256 timestamp = block.timestamp;
      uint256 mintRate = pcoin.calcultionMintRate(timestamp);
      pcoin.updateMintContext(supply, mintRate, timestamp);
    }
  }

  function _updateReward(
    GunPoolContext.RewardContext storage reward,
    GunPoolContext.PcoinReward memory pcoin
  )
    internal
  {
    uint256 preSupply = reward.lastGpBalance.mul(reward.lastMintCapacity);
    uint256 curSupply = reward.lastGpBalance.mul(pcoin.mintCapacity);
    uint256 rewardAmount = curSupply.sub(preSupply);

    if ( rewardAmount > 0 ) {
      reward.rewardSupply = reward.rewardSupply.add(rewardAmount.div(WadRayMath.ray()));
    }
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }

  /*
  * @dev approve aoken to aave plane from this address
  * @param token find reserve from aave
  * @param lpAddress is lendingPool address for aave
  */
  function _authorizeAAVEPlane(
    address token,
    address plane
  )
    internal
  {
    IERC20(token).approve(plane, type(uint256).max);
  }

  /**
   * @dev Only _IWETH contract is allowed to transfer ETH here.
   *   Prevent other addresses to send Ether to this contract.
   */
  receive() external payable {
    require(msg.sender == address(_IWETH), 'Receive not allowed');
  }

  /**
   * @dev Revert fallback calls
   */
  fallback() external payable {
    revert('Fallback not allowed');
  }
}
