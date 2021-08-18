// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {AccessControl} from "../../dependencies/openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "../../dependencies/openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "../../dependencies/openzeppelin/contracts/utils/math/SafeMath.sol";

contract PolylendToken is ERC20, AccessControl {
    using SafeMath for uint256;

    /******** Key Variable ********/
    /*
    * Polylend token Context contains:
    *   name, symbol, max supply
    */
    string internal constant NAME = 'Polylend Token';
    string internal constant SYMBOL = 'PCOIN';
    // the max supply of pcoin
    uint256 immutable private MAXSUPPLY;
    // the accounts who has pcoin
    uint32 public _accountCounts;

    /*
    * minter role: MINTER_ROLE
    *   call grantRole to add minter:
    *     for example: grantRole(MINTER_ROLE, address_contract)
    *   call revokeRole to del minter
    *     for example: revokeRole(MINTER_ROLE, address_contract)
    */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /*
    * for permit
    */
    bytes32 public DOMAIN_SEPARATOR;
    bytes public constant EIP712_REVISION = bytes('1');
    bytes32 internal constant EIP712_DOMAIN = keccak256(
    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
    'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
    );
    // @dev owner => next valid nonce to submit with permit()
    mapping(address => uint256) public _nonces;

    /*
    * for snapshots: for user trace their accounts
    */
    struct SnapshotContext {
        uint128 block;
        uint128 balance;
    }
    struct Snapshot {
        SnapshotContext[] content;
    }
    mapping (address => Snapshot) private _snapshot;

    /******** Event ********/
    /*
    * Mint event will be called by mint process
    *  to report who has obtained the amount of pcoin
    */
    event Mint(address indexed to, uint256 amount);
    /*
    * Burn event
    */
    event Burn(address indexed from, uint256 amount);
    /*
    * SnapshotRecord event
    */
    event SnapshotRecord(address indexed account,
                         uint128 block,
                         uint128 amount);

    /*
    * set admin role for pcoin by constructor account
    */
    constructor (uint256 maxSupply) ERC20(NAME, SYMBOL)
    {
        uint256 multiBase = 10**(decimals());
        MAXSUPPLY = maxSupply.mul(multiBase);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _accountCounts = 0;
    }

    /*
    * @dev initialize the contract
    *   init DOMAIN_SEPARATOR for permit
    */
    function initialize()
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is initialize by admin");

        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
            EIP712_DOMAIN,
            keccak256(bytes(NAME)),
            keccak256(EIP712_REVISION),
            chainId,
            address(this)
            )
        );
    }

    /*
    * get max supply for pcoin
    */
    function getMaxSupply()
        external
        view
        returns (uint256)
    {
        uint256 multiBase = 10**(decimals());
        return MAXSUPPLY.div(multiBase);
    }

    /*
    * get snapshot
    */
    function getSnapshot(address account)
        external
        view
        returns (Snapshot memory)
    {
        return _snapshot[account];
    }

    /*
    * @dev changeAdmin will change admin from msgSender(old admin) to newaccount
    * @param newdmin who will become admin
    */
    function changeAdmin(address newadmin)
        external
    {
        grantRole(DEFAULT_ADMIN_ROLE, newadmin);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*
    * @dev mint will mint pcoin to account by minter
    * @param account who will get pcoin
    * @param amount the value of pcoin
    */
    function mint(address account, uint256 amount)
        external
    {
        uint256 preSupply = super.totalSupply();
        bool addRet = false;

        (addRet, preSupply) = preSupply.tryAdd(amount);

        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
//        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a minter");
        require(addRet, "Mint stop for overflow");
        require(preSupply <= MAXSUPPLY, "Mint stop by total supply more than max");
        _mint(account, amount);

        emit Mint(account, amount);
    }

    /*
    * @dev burn will burn pcoin from account
    * @param amount the burn amount of pcoin by account self
    */
    function burn(uint256 amount)
        external
    {
        _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }

    /**
    * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
    * @param owner the owner of the funds
    * @param spender the spender
    * @param value the amount
    * @param deadline the deadline timestamp, type(uint256).max for no deadline
    * @param v signature param
    * @param s signature param
    * @param r signature param
    */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    {
        require(owner != address(0), 'OWNER_IS_ZERO');
        //solium-disable-next-line
        require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
        uint256 currentValidNonce = _nonces[owner];
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
            )
        );

        require(owner == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
        _nonces[owner] = currentValidNonce.add(1);
        _approve(owner, spender, value);
    }

    /*
    * record snapshots for from/to account
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        virtual
        override
    {
        if ( from == to || amount == 0 ) {
            return;
        }
        uint256 balance = 0;

        if ( from != address(0) ) {
            balance = balanceOf(from);
            _recordSnapshot(from, (uint128)(balance));
            if ( balance == amount ) {
                _accountCounts--;
            }
        }

        if ( to != address(0) ) {
            balance = balanceOf(to);
            _recordSnapshot(to, (uint128)(balance));
            if ( balance == 0 ) {
                _accountCounts++;
            }
        }
    }

    /*
    * record snapshot for previously balance of user
    */
    function _recordSnapshot(
        address account,
        uint128 balance
    )
        internal
    {
        uint128 curBlock = uint128(block.number);

        SnapshotContext[] storage snapshot = _snapshot[account].content;
        uint256 length = snapshot.length;

        if ( length == 0 ) {
            snapshot.push( SnapshotContext(curBlock, balance) );
        }
        else {
            if ( snapshot[length-1].block < curBlock ) {
                snapshot.push( SnapshotContext(curBlock, balance) );
            }
            else {
                return;
            }
        }

        emit SnapshotRecord(account, curBlock, balance);
    }
}
