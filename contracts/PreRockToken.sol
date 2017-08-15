pragma solidity ^0.4.11;

import './StandardToken.sol';
import './Ownable.sol';

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will recieve the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner returns (bool) {
        return mintInternal(_to, _amount);
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function mintInternal(address _to, uint256 _amount) internal canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }
}

contract PreRockToken is MintableToken {

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public minFundedEthValue;

    mapping(address => uint256) public donations;

    uint256 public totalWeiFunded;

    uint256 public maxTokensToMint;

    // address where funds are collected
    address public wallet;

    // how many wei a buyer gets per token
    uint256 public rate;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function PreRockToken(
    uint256 _rate,
    uint256 _maxTokensToMint,
    uint256 _minValue,
    address _wallet,
    string _name,
    string _symbol,
    uint8 _decimals
    ) {
        require(_rate > 0);
        require(_wallet != 0x0);

        minFundedEthValue = _minValue;
        rate = _rate;
        maxTokensToMint = _maxTokensToMint;
        wallet = _wallet;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address _to, uint _value) onlyOwner returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) onlyOwner returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function () payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) payable {
        require(beneficiary != 0x0);
        require(msg.value > 0);

        uint256 weiAmount = msg.value;
        uint8 bonus = getBonusPercents();

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        if(bonus > 0){
            tokens += tokens * bonus / 100;    // add bonus
        }

        require(totalSupply + tokens <= maxTokensToMint);

        totalWeiFunded += msg.value;
        donations[msg.sender] += msg.value;

        mintInternal(beneficiary, tokens);
        TokenPurchase(
        msg.sender,
        beneficiary,
        weiAmount,
        tokens
        );

        forwardFunds();
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function getBonusPercents() internal returns(uint8){
        uint8 percents = 0;

        if(now >= 1502755200 && now <= 1503014399){    //15-08-17 (UTC 00:00) - 17-08-17 (UTC 23:59) - bonus 60%
            percents = 60;
        }

        if(now >= 1503014400 && now <= 1503446399){    //18-08-17 (UTC 00:00) – 22-08-17 (UTC 23:59) - bonus 50%
            percents = 50;
        }

        if(now >= 1503446400 && now <= 1504051199){    //23-08-17 (UTC 00:00) – 29-08-17 (UTC 23:59) - bonus 40%
            percents = 40;
        }

        if(now >= 1504051200 && now <= 1504655999){    //30-08-17 (UTC 00:00) – 05-09-17 (UTC 23:59) - bonus 30%
            percents = 30;
        }

        return percents;
    }

}


