// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

//import "./ERC20/base/ERC20.sol";
//import "./Library/SafeMath.sol";

contract Pcoin {

  string private _name = "Polylend Coin";
  string private _symbol = "PCOIN"; //
  uint8 private _decimals = 18;
  uint256 _totalSupply = 0; //当前已发量
  uint256 immutable private _maxSupply;   //总发行量上限
  mapping(address => uint256) private _balances; //账户余额
  mapping(address => mapping(address => uint256)) private _allowances; //授权剩余余额
  address private _burnAddress; //烧币地址

  //分层管理结构
  address private _governance; //super user
  /*
  第二层管理者（外部账户或合约账户，合约账户能动态选择挖矿池，外部账户人工选择挖矿池）
  mapping(address => bool) private _admin;
  */
  mapping(address => bool) private _minter;  //挖矿账户

  //备用数据。暂未使用
  //mapping(address => uint256) private _lockCoin ; //出现突发状况将用户余额转移此处，不提供访问此映射的接口
  //mapping(address => uint256) private _plToken; //凭证记录，可用于金额安全验证

  //using SafeMath for uint256;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor (
    uint256 maxSupply_,
    address governance_,
    address burnAddress_
  ) public {
    _maxSupply = maxSupply_;
    _governance = governance_;
    _burnAddress = burnAddress_;
  }

  modifier onlyManager {
    bool manager = (_msgSender() == _governance);
    require(manager, "Manager : illegal account.");
    _;
  }

  modifier onlyMinter {
    bool minter = (_msgSender() == _governance || _minter[_msgSender()]);
    require(minter, "Minter : illegal account.");
    _;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view  returns (uint256) {
    return _totalSupply;
  }

  function maxSupply() public view returns (uint256) {
    return _maxSupply;
  }

  function balanceOf(address account) public view  returns (uint256) {
    return _balances[account];
  }

  function governance() public view returns (address) {
    return _governance;
  }

  function burnAddress() public view returns (address) {
    return _burnAddress;
  }
/*
  function isAdmin(address account) public view returns (bool) {
      if(_admin[account]) return true;
      else return false;
  }
*/
  function isMinter(address account) public view returns (bool) {
      if(_minter[account] || account == _governance) return true;
      else return false;
  }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal pure returns (bytes calldata) {
    return msg.data;
  }

  function approve(address spender, uint256 amount) public returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal{
    require(owner != address(0), "ERC20: approve from the zero address.");
    require(spender != address(0), "ERC20: approve to the zero address.");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowances[owner][spender];
  }

  function transfer(address recipient, uint256 amount) public returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    require(sender != address(0), "ERC20: transfer from the the zero address.");
    require(recipient != address(0), "ERC20: transefer to zero address.");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance.");

      _balances[sender] = senderBalance - amount;

    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance.");

      _approve(sender, _msgSender(), currentAllowance - amount);


    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero.");

      _approve(_msgSender(), spender, currentAllowance - subtractedValue);


    return true;
  }

  function mint(address account, uint256 token) public onlyMinter {
    _mint(account, token);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "PLC: mint to the zero address.");
    require(totalSupply() + amount <= maxSupply(), "PLC: totalSupply exceeded");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  function burn(uint256 amount) public {
    _burn(_msgSender(), amount);
  }
//
//  function burnFrom(address account, uint256 amount) public {
//    _burn(account, amount);
//  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: burn from the zero address.");

    _beforeTokenTransfer(account, address(0), amount);

    //检查burn金额是否超过授权金额
    if (account != _msgSender()){
      require(_allowances[account][_msgSender()] >= amount, "ERC20: burn over the allowance.");

        _allowances[account][_msgSender()] -= amount;

    }

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance.");

      _balances[account] = accountBalance - amount;

    _totalSupply -= amount;
    _balances[_burnAddress] += amount;

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * has been transferred to `to`.
   * - when `from` is zero, `amount` tokens have been minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
      address from,
      address to,
      uint256 amount
  ) internal {}
/*
  function addAdmin(address account) public {
    require(msg.sender == _governance, "illegal account.");
    _admin[account] = true;
  }

  function removeAdmin(address account) public {
    require(msg.sender == _governance, "illegal account.");
    _admin[account] = false;
  }
*/

  function modifyGovernance(address account) public onlyManager returns (bool) {
    _governance = account;
    return true;
  }

  function modifyBurnAddress(address account) public onlyManager returns (bool) {
    _burnAddress = account;
    return true;
  }

  function addMinter(address account) public onlyManager {
    _minter[account] = true;
  }

  function removeMinter(address account) public onlyManager {
    _minter[account] = false;
  }

}
