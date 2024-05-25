// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract AmirERC20 is ERC20, ERC20Burnable, Ownable {

    constructor()
        ERC20("AmirERC20", "AFT")
        Ownable(msg.sender){
        _mint(msg.sender, 1000 * 10 ** decimals());

    }

    function decimals() public view virtual override returns (uint8) {
        return 12;
    }

    function getBalance() public view {
        console.log(ERC20.balanceOf(address(this)));
    }
}

contract shop{

    address private initial_owner;
    AmirERC20 private AFT_token;
    event buyAFT (address sender, uint256 _amount);
    event sellAFT (address sender, uint256 _amount);
    uint256 coefficient = 1000;
    

    constructor(address initialOwner, address token){
        initial_owner = initialOwner;
        AFT_token = AmirERC20(token);
    }

    modifier onlyOwner(){
        require((msg.sender == initial_owner), "You are not the owner of this shop");
        _;
    }

    function token_balance() public onlyOwner view returns (uint256){

        return AFT_token.balanceOf(address(this));
    }

    function user_AFT_balance() public view returns (uint256){

        return AFT_token.balanceOf(address(msg.sender));
    }

    function showETHbalance() public payable returns(uint256){

        console.log(msg.sender.balance);
        return msg.sender.balance;
    }

    function showETHbalance(address user) public payable returns(uint256){

        console.log(user.balance);
        return user.balance;
    }

    function buy() public payable{

        require(msg.value >= 0, "Insufficient ETH amount");
        require(AFT_token.balanceOf(address(this)) >= ETHtoAFT(msg.value));
        uint256 tokensToBuy = ETHtoAFT(msg.value);
        AFT_token.transfer(msg.sender, tokensToBuy);

        emit buyAFT(msg.sender, msg.value);
    }

    function sell(uint256 _amount) payable public{

        uint256 ETHtoGet = AFTtoETH(_amount);
        uint256 balance = AFT_token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient AFT amount");

        AFT_token.transferFrom(msg.sender, address(this), _amount);

        (bool sent, bytes memory data) = payable(msg.sender).call{value: ETHtoGet}("");
        require(sent, "Failed to send Ether");

        emit sellAFT(msg.sender, msg.value);

    }

    function ETHtoAFT(uint256 _amount) public view returns (uint256 out){
        return _amount / coefficient;
    }

    function AFTtoETH(uint256 _amount) public view returns (uint256 out){
        return _amount * coefficient;
    }
}

