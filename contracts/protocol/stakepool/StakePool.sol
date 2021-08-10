// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import {StakePoolContext} from "./StakePoolContext.sol";
import {SpError} from "./helper/SpError.sol";
import {IStakePool} from "../../interfaces/IStakePool.sol";
import {IGunPool} from "../../interfaces/IGunPool.sol";
import {GunPoolContext} from "../gunpool/GunPoolContext.sol";
import {ILendingPool} from "../gunpool/pools/aave/ILendingPool.sol";
import {WadRayMath} from "../gunpool/pools/aave/WadRayMath.sol";
import {Ownable} from "../../dependencies/openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "../../dependencies/openzeppelin/contracts/math/SafeMath.sol";

contract StakePool is Ownable, IStakePool {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    /******** Key Variables ********/
    // order context
    StakePoolContext.Order _order;
    // user context
    StakePoolContext.User _users;
    // pcoin address
    address private _pcoin;
    // gunpool address
    address private _gunpool;
    // IWETH address
    address private _iweth;

    constructor (
        address pcoinAddress,
        address gunpoolAddress,
        address iwethAddress
    )
        public
    {
        _order.state = StakePoolContext.ORDER_STATUS.INIT;
        delete _users.accounts;
        _users.totalSupply = 0;
        _pcoin = pcoinAddress;
        _gunpool = gunpoolAddress;
        _iweth = iwethAddress;
        _order.stateTime.push(block.timestamp);
    }

    /*
    * init order: start new order by configure parameters
    *    primary key is order index
    */
    function initOrder(
        StakePoolContext.OrderInitParam calldata orderParam
    )
        external
        override
        onlyOwner
        returns (uint128)
    {
        require(_order.state == StakePoolContext.ORDER_STATUS.INIT, SpError.ORDER_INIT_FAIL_FOR_STATE);
        require(orderParam.proxy == address(0), SpError.ORDER_PROXY_INVALID);
        _order.id = orderParam.id;
        _order.threshold = orderParam.threshold;
        if ( orderParam.period >= 90 ) {
            _order.period = 90;
        } else if ( orderParam.period >= 60 ) {
            _order.period = 60;
        } else {
            _order.period = 30;
        }

        _order.proxy = orderParam.proxy;
        _order.pcoinReward = orderParam.pcoinReward;
        _order.feeTo = orderParam.feeTo;
        if ( orderParam.feePermillage <= StakePoolContext.FEE_PERMILLAGE_MAX ) {
            _order.feePermillage = orderParam.feePermillage;
        }
        else {
            _order.feePermillage = StakePoolContext.FEE_PERMILLAGE_MAX;
        }

        _order.state = StakePoolContext.ORDER_STATUS.SUBSCRIBE;
        _order.stateTime.push(block.timestamp);
        emit InitOrder(_order);
        emit StatusTransfer(_order.id,
                            StakePoolContext.ORDER_STATUS.INIT,
                            StakePoolContext.ORDER_STATUS.SUBSCRIBE);
        return _order.id;
    }

    /*
    * user delegate matic in order status(SUBSCRIBE or MIGRATE)
    *   During subscribe state, user can get reward by gunpool
    *   During migrate state, user can delegate continuity
    */
    function delegate()
        external
        payable
        override
    {
        require(msg.value >= StakePoolContext.DELEGATE_AMOUNT_MIN, SpError.DELEGATE_AMOUNT_INVALID);
        address account = msg.sender;
        uint256 amount = msg.value;

        if ( _order.state == StakePoolContext.ORDER_STATUS.SUBSCRIBE ) {
            _subscribeDeposit(account, amount);
        }
        else if ( _order.state == StakePoolContext.ORDER_STATUS.MIGRATE ) {
            _migrate(account, amount);
        }
        else {
            require(false, SpError.ORDER_DELEGATE_FAIL_FOR_STATE);
        }

        _addUser(account);

        emit Delegate(_order.id, account, msg.value);
    }

    function undelegate(uint256 amount)
        external
        override
    {
        require(amount > 0, SpError.DELEGATE_AMOUNT_ZERO);
        require(_order.state == StakePoolContext.ORDER_STATUS.SUBSCRIBE, SpError.UNDELEGATE_NOT_SUBSCRIBE);

        address account = msg.sender;

        uint256 withdrawAmount = _subscribeWithdraw(account, amount);

        emit UnDelegate(_order.id, account, withdrawAmount);
    }

    function lock()
        external
        override
        onlyOwner
    {
        _safeTransferETH(_order.proxy, _users.totalSupply);
        emit Migrate(_order.id, _order.proxy, _users.totalSupply);
        // status change
        _order.stateTime.push(block.timestamp);
        _order.state = StakePoolContext.ORDER_STATUS.LOCKING;
        emit StatusTransfer(_order.id,
            StakePoolContext.ORDER_STATUS.MIGRATE,
            StakePoolContext.ORDER_STATUS.LOCKING);
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        uint256 balance = _users.balances[account];
        if ( _order.state == StakePoolContext.ORDER_STATUS.SUBSCRIBE ) {
            uint256 index = _getIncome();
            return balance.rayMul(index);
        }
        else {
            return balance;
        }
    }

    function totalSupply()
        external
        view
        override
        returns (uint256)
    {
        uint256 supply = _users.totalSupply;

        if ( _order.state == StakePoolContext.ORDER_STATUS.SUBSCRIBE ) {
            uint256 index = _getIncome();
            return supply.rayMul(index);
        }
        else {
            return supply;
        }
    }

    /****** internal function ******/
    // add user into delegate set
    function _addUser(address account) internal
    {
        bool isDelegater = _users.delegates[account];
        if ( !isDelegater ) {
            _users.delegates[account] = true;
            _users.accounts.push(account);
        }
    }

    function _subscribeDeposit(address account, uint256 amount)
        internal
    {
        uint256 balance = _users.balances[account];
        uint256 supply = _users.totalSupply;
        uint256 index = _getIncome();

        _users.balances[account] = balance.add(amount.rayDiv(index));
        _users.totalSupply = supply.add(amount.rayDiv(index));

        if ( _users.totalSupply.rayMul(index) >= _order.threshold ) {   // withdraw matic from gunpool
            supply = 0;
            for ( uint256 i = 0; i < _users.accounts.length; i++ ) {
                balance = _users.balances[account];
                _users.balances[account] = balance.rayMul(index);
                supply = supply.add(_users.balances[account]);
            }

            IGunPool(_gunpool).withdrawByEth( uint256(-1) );
            _users.totalSupply = supply;

            if ( _users.totalSupply > address(this).balance ) {
                emit Warn(_order.id, "_users.totalSupply more than contract balance in _subscribeDeposit");
            }

            _order.stateTime.push(block.timestamp);
            _order.state = StakePoolContext.ORDER_STATUS.MIGRATE;
            emit StatusTransfer(_order.id,
                StakePoolContext.ORDER_STATUS.SUBSCRIBE,
                StakePoolContext.ORDER_STATUS.MIGRATE);
        }
        else {  // deposit matic into gunpool
            if ( address(this).balance > 0 ) {
                IGunPool(_gunpool).depositByEth{value: amount}();
            }
        }
    }

    function _subscribeWithdraw(address account, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 withdrawAmount = amount;
        uint256 index = _getIncome();
        uint256 balance = _users.balances[account];
        uint256 supply = _users.totalSupply;
        bool isClear = false;

        balance = balance.rayMul(index);
        supply = supply.rayMul(index);

        if ( (amount == uint256(-1)) || (amount > balance) ) {
            withdrawAmount = balance;
        }

        if ( supply < withdrawAmount ) {
            withdrawAmount = supply;
            emit Warn(_order.id, "Supply less than withdrawAmount when _subscribeWithdraw");
            isClear = true;
        }

        if ( withdrawAmount > 0 ) {
            IGunPool(_gunpool).withdrawByEth( withdrawAmount );
            _safeTransferETH(account, withdrawAmount);
        }

        if ( isClear ) {
            _users.balances[account] = 0;
            _users.totalSupply = 0;
        } else {
            _users.balances[account] = balance.sub(withdrawAmount);
            _users.totalSupply = supply.sub(withdrawAmount);
        }

        return withdrawAmount;
    }

    function _migrate(address account, uint256 amount)
        internal
    {
        uint256 balance = _users.balances[account];
        uint256 supply = _users.totalSupply;

        _users.balances[account] = balance.add(amount);
        _users.totalSupply = supply.add(amount);
    }

    function _getIncome()
        internal
        view
        returns (uint256)
    {
        GunPoolContext.ReserveData memory reserve = IGunPool(_gunpool).getReserve(_iweth);
        if ( reserve.pt == GunPoolContext.PlaneType.AAVE ) {
            GunPoolContext.PlaneContext memory plane = IGunPool(_gunpool).getPlanes(_iweth, reserve.pt);
            ILendingPool lendingPool = ILendingPool(plane.plane);
            return lendingPool.getReserveNormalizedIncome(_iweth);
        }
        else {
            return 1;
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

    receive() external payable {
        //require(msg.sender == address(_IWETH), 'Receive not allowed');
    }
}