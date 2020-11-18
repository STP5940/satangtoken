pragma solidity 0.5.16;

// ----------------------------------------------------------------------------
// 'SA' token contract
//
// Symbol      : SA
// Name        : Satang Token
// Total supply: 1000000000
// Decimals    : 2
//
//
// ███████╗ █████╗ ████████╗ █████╗ ███╗   ██╗ ██████╗ 
// ██╔════╝██╔══██╗╚══██╔══╝██╔══██╗████╗  ██║██╔════╝ 
// ███████╗███████║   ██║   ███████║██╔██╗ ██║██║  ███╗
// ╚════██║██╔══██║   ██║   ██╔══██║██║╚██╗██║██║   ██║
// ███████║██║  ██║   ██║   ██║  ██║██║ ╚████║╚██████╔╝
// ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
//
// (c) by satangtoken Nev 2020. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// @dev Math operations with safety checks that throw on error
// ----------------------------------------------------------------------------
library SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, 'SafeMath add failed');
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, 'SafeMath sub failed');
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, 'SafeMath mul failed');
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract SatangToken is owned  {

    // ----------------------------------------------------------------------------
    //         DATA STORAGE          
    // ----------------------------------------------------------------------------

    // Public variables of the token
    using SafeMath for uint256;
    string constant private _name = "Satang Token";
    string constant private _symbol = "SA";
    uint256 constant private _decimals = 2;
    uint256 private _totalSupply = 1000000000 * (10**_decimals);         //800 million tokens
    bool public safeguard;  //putting safeguard on will halt all non-owner functions
    
    // This creates a mapping with all data storage
    mapping (address => uint256) private _balanceOf;
    mapping (address => bool) public frozenAccount;
    
    // ----------------------------------------------------------------------------
    //         PUBLIC EVENTS         
    // ----------------------------------------------------------------------------

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address target, bool frozen);
    
    // This will log approval of token Transfer
    /* event Approval(address indexed from, address indexed spender, uint256 value); */
    



    // ----------------------------------------------------------------------------
    //         STANDARD ERC20 FUNCTIONS       
    // ----------------------------------------------------------------------------
    
     // Returns name of token 
    function name() public pure returns(string memory){
        return _name;
    }
    
     // Returns symbol of token 
    function symbol() public pure returns(string memory){
        return _symbol;
    }
    
    // Returns decimals of token 
    function decimals() public pure returns(uint256){
        return _decimals;
    }
    
    // Returns totalSupply of token.
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    // Returns balance of token 
    function balanceOf(address user) public view returns(uint256){
        return _balanceOf[user];
    }

    // Internal transfer, only can be called by this contract 
    function _transfer(address _from, address _to, uint _value) internal {
        //checking conditions
        require(!safeguard);
        require (_to != address(0));    // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]); // Check if sender is frozen
        require(!frozenAccount[_to]);   // Check if recipient is frozen
        
        // overflow and undeflow checked by SafeMath Library
        _balanceOf[_from] = _balanceOf[_from].safeSub(_value);    // Subtract from the sender
        _balanceOf[_to] = _balanceOf[_to].safeAdd(_value);        // Add the same to the recipient

        emit Transfer(_from, _to, _value); // emit Transfer event
    }

    // Transfer tokens
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }




    // ----------------------------------------------------------------------------
    //         CUSTOM PUBLIC FUNCTIONS
    // ----------------------------------------------------------------------------

    constructor() public{
        // sending all the tokens to Owner
        _balanceOf[owner] = _totalSupply;
        // firing event which logs this transaction
        emit Transfer(address(0), owner, _totalSupply);
    }

    // burn tokens from the ecosystem irreversibly
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(!frozenAccount[msg.sender]);   // Check if sender is frozen

        // checking of enough token balance
        _balanceOf[msg.sender] = _balanceOf[msg.sender].safeSub(_value);  // Subtract from the sender
        _totalSupply = _totalSupply.safeSub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    // Run an ACTIVE Air-Drop addresses and amount of tokens to distribute only process first 150 recipients
    function airdropACTIVE(address[] memory recipients, uint256[] memory tokenAmount) public returns(bool) {
        require(!safeguard);
        require(!frozenAccount[msg.sender]);   // Check if sender is frozen

        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150, "Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          // This will loop through all the recipients and send them the specified tokens
          transfer(recipients[i], tokenAmount[i]); //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
        }
        return true;
    }




    // ----------------------------------------------------------------------------
    //         ONLY OWNER FUNCTIONS
    // ----------------------------------------------------------------------------

    // freeze: Prevent or Allow target from sending & receiving tokens
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }

    // Change safeguard status on
    function safeguardOff() onlyOwner public{
        safeguard = false;
    }

    // Change safeguard status off
    function safeguardOn() onlyOwner public{
        safeguard = true;
    }
    
}
