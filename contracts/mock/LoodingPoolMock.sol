// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;

import {SafeMath} from "../dependencies/openzeppelin/contracts/math/SafeMath.sol";

contract LoodingPoolMock {
  using SafeMath for uint256;

  uint256 _lastBlockTime;
  address _asset;
  uint256 _curBlockTime;
  uint256 _index;

  constructor (address asset) public {
    _lastBlockTime = block.timestamp;
    _asset = asset;
    _curBlockTime = _lastBlockTime;
    _index = 10**8;
  }

  function setCurBlockTime(uint256 timestamp)
    external
  {
    _lastBlockTime = _curBlockTime;
    _curBlockTime = timestamp;
  }

  function getReserveNormalizedIncome(address asset)
    external
    view
    returns (uint256)
  {
    require(asset == _asset, "asset different");
    if ( _lastBlockTime >= _curBlockTime ) {
      return _index;
    }
    else {
      uint256 ret = (10**4)*(_curBlockTime-_lastBlockTime);
      return _index.add(ret);
    }
  }

  function getLastBlockTime()
    external
    view
    returns (uint256)
  {
    return _lastBlockTime;
  }
}

/*
import {ILendingPool} from "../protocol/gunpool/pools/aave/ILendingPool.sol";
import {DataTypes} from "../protocol/gunpool/pools/aave/DataTypes.sol";

contract LoodingPoolMock is ILendingPool {

  uint256 _lastBlockTime;

  constructor () public {
    _lastBlockTime = block.timestamp;
  }

  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external override {
    return;
  }

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external override returns (uint256) {
    return amount;
  }

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external override
  {
    return;
  }

  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external override returns (uint256)
  {
    return amount;
  }

  function swapBorrowRateMode(address asset, uint256 rateMode)
    external override
  {
    return;
  }

  function rebalanceStableBorrowRate(address asset, address user)
    external override
  {
    return;
  }

  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
    external override
  {
    return;
  }

  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external override
  {
    return;
  }

  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external override
  {
    return;
  }

  function getUserAccountData(address user)
    external
    override
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    return (0,0,0,0,0,0);
  }

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external override
  {
    return;
  }

  function setReserveInterestRateStrategyAddress(
    address reserve,
    address rateStrategyAddress
  ) external override
  {
    return;
  }

  function setConfiguration(
    address reserve,
    uint256 configuration)
    external override
  {
    return;
  }

  function getConfiguration(address asset)
    external
    view
    override
    returns (DataTypes.ReserveConfigurationMap memory)
  {
    DataTypes.ReserveConfigurationMap memory ret;
    return ret;
  }

  function getUserConfiguration(address user)
    external
    view
    override
    returns (DataTypes.UserConfigurationMap memory)
  {
    DataTypes.UserConfigurationMap memory ret;
    return ret;
  }

  function getReserveNormalizedIncome(address asset)
    external
    view
    override
    returns (uint256)
  {
    // todo
    return 0;
  }

  function getReserveNormalizedVariableDebt(address asset)
    external
    view
    override
    returns (uint256)
  {
    return 0;
  }

  function getReserveData(address asset)
    external
    view
    override
    returns (DataTypes.ReserveData memory)
  {
    DataTypes.ReserveData memory ret;
    return ret;
  }

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external
    override
  {
    return;
  }

  function getReservesList()
    external
    view
    override
    returns (address[] memory)
  {
    address[] memory ret = new address[](2);
    return ret;
  }

  function setPause(bool val) external override {
    return;
  }

  function paused() external view override returns (bool) {
    return true;
  }
} */
