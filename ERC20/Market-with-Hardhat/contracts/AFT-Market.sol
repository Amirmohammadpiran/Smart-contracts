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

contract AFT_Market{

    address private initial_owner;
    AmirERC20 private AFT_token;
    event buyAFT (address sender, uint256 _amount);
    event sellAFT (address sender, uint256 _amount);
    uint256 order_counter = 0;
    uint256 private market_total_offers;
    uint256 private market_total_requests;

    struct BUY {
        uint256 orderID;
        address buyer;
        uint256 payed_ETH;
        uint256 price;
        uint256 equivalent_AFT;
        uint256 created_time;
        uint256 finished_time;
        uint256 remained_AFT;  // will go from equivalent_AFT to 0 when finished
        bool is_done;
    }
    struct SELL {
        uint256 orderID;
        address seller;
        uint256 payed_AFT;
        uint256 price;
        uint256 equivalent_ETH;
        uint256 created_time;
        uint256 finished_time;
        uint256 remained_AFT;  // will go from payed_AFT to 0 when finished
        bool is_done;
    }
    BUY[] public buy_list;
    SELL[] public sell_list;
    BUY[] public completed_buy_list;
    SELL[] public completed_sell_list;
    

    constructor(){
        initial_owner = msg.sender;
        market_total_offers = 0;
        market_total_requests = 0;
    }

    modifier onlyOwner(){
        require((msg.sender == initial_owner), "You are not the owner of this shop");
        _;
    }

    modifier onlyMarket(){
        require((msg.sender == address(this)), "Only the market is allowed");
        _;
    }

    function assign_token(address token) public onlyOwner{

        AFT_token = AmirERC20(token);
    }

    function token_balance() public onlyOwner view returns (uint256){

        return AFT_token.balanceOf(address(this));
    }

    function user_AFT_balance() public view returns (uint256){

        return AFT_token.balanceOf(address(msg.sender));
    }

    function showETHbalance(address user) public payable returns(uint256){

        return user.balance;
    }

    function total_requests_AFT() public view{
        console.log(market_total_requests);
        return;
    }

    function total_offers_AFT() public view{
        console.log(market_total_offers);
        return;
    }

    function BuyAFT(uint256 price) public payable{

        require(msg.value <= address(msg.sender).balance, "Insufficient ETH amount");
        uint256 tokensToBuy = WEItoAFT_with_profit(msg.value, price);
        BUY memory order = BUY(order_counter++, msg.sender, msg.value, price, 
                               tokensToBuy, block.timestamp, 0, tokensToBuy, false);
        
        if (sell_list.length == 0 || sell_list[sell_list.length-1].is_done){
            print_buy_creation(order);
            buy_list.push(order);
            market_total_requests += order.remained_AFT;
        }
        else if (tokensToBuy > market_total_offers){
            
            print_buy_creation(order);
            market_total_requests += order.remained_AFT;
            order.remained_AFT = this._match_buy(order);
            buy_list.push(order);
            console.log("\n-Wait for your order to fill.");
        }
        else {
            market_total_requests += order.remained_AFT;
            order.remained_AFT = this._match_buy(order);
        }

        emit buyAFT(msg.sender, msg.value);

    }

    function _match_buy(BUY memory order) public onlyMarket payable returns (uint256){

        for(uint256 i=0; i<sell_list.length; i++){

            if (order.price != sell_list[i].price || sell_list[i].is_done){
                continue;
            }

            if (sell_list[i].remained_AFT > order.remained_AFT){

                AFT_token.transfer(order.buyer, order.remained_AFT);
                
                (bool sent, bytes memory data) = payable(sell_list[i].seller).call{value: AFTtoWEI(order.remained_AFT, order.price)}("");
                require(sent, "Failed to send Ether");
                sell_list[i].remained_AFT -= order.remained_AFT;

                market_total_offers -= order.remained_AFT;
                market_total_requests -= order.remained_AFT;    
                completed_buy_list.push(order);
                print_buy_completion(order);
                return 0;
            }
            else if (sell_list[i].remained_AFT == order.remained_AFT){

                AFT_token.transfer(order.buyer, order.remained_AFT);

                (bool sent, bytes memory data) = payable(sell_list[i].seller).call{value: AFTtoWEI(order.remained_AFT, order.price)}("");
                require(sent, "Failed to send Ether");
                
                market_total_requests -= order.remained_AFT;
                market_total_offers -= order.remained_AFT;
                print_sell_completion(sell_list[i]);
                print_buy_completion(order);
                completed_sell_list.push(sell_list[i]);
                completed_buy_list.push(order);
                sell_list[i].is_done = true;
                return 0;
            }
            else { // if(sell_list[i].remained_AFT < order.remained_AFT)

                AFT_token.transfer(order.buyer, sell_list[i].remained_AFT);
                
                (bool sent, bytes memory data) = payable(sell_list[i].seller).call{value: AFTtoWEI(sell_list[i].remained_AFT, order.price)}("");
                require(sent, "Failed to send Ether");
                
                market_total_offers -= sell_list[i].remained_AFT;
                order.remained_AFT -= sell_list[i].remained_AFT;
                market_total_requests -= sell_list[i].remained_AFT;

                print_sell_completion(sell_list[i]);
                completed_sell_list.push(sell_list[i]);
                sell_list[i].is_done = true;
            }
            

            if (order.remained_AFT == 0){  // the order is filled

                print_buy_completion(order);
                return 0;
            }
        }
        return order.remained_AFT;
    }

    function SellAFT(uint256 amount, uint256 price) public payable{

        require(AFT_token.balanceOf(msg.sender) >= amount, "Insufficient AFT amount");        
        require(AFT_token.allowance(msg.sender, address(this)) >= amount, "Market contract not approved to transfer tokens");
        uint256 ETHtoGet = AFTtoWEI_with_profit(amount, price);
        SELL memory order = SELL(order_counter++, msg.sender, amount, price, 
                                 ETHtoGet, block.timestamp, 0, WEItoAFT(ETHtoGet, price), false);

        AFT_token.transferFrom(order.seller, address(this), amount);

        if (buy_list.length == 0 || buy_list[buy_list.length-1].is_done){

            print_sell_creation(order);            
            sell_list.push(order);
            market_total_offers += order.remained_AFT;
        }
        else if (amount > market_total_requests){
            
            print_sell_creation(order);
            market_total_offers += order.remained_AFT;
            order.remained_AFT = this._match_sell(order);

            sell_list.push(order);
            console.log("\n-Wait for your order to fill.");
        }
        else {
            market_total_offers += order.remained_AFT;
            order.remained_AFT = this._match_sell(order);
        }

        emit sellAFT(msg.sender, msg.value);

    }


    function _match_sell(SELL memory order) public onlyMarket payable returns (uint256){

        for(uint256 i=0; i<buy_list.length; i++){

            if (buy_list[i].price != order.price || buy_list[i].is_done){
                continue;
            }

            if (buy_list[i].remained_AFT > order.remained_AFT){

                AFT_token.transfer(buy_list[i].buyer, order.remained_AFT);

                (bool sent, bytes memory data) = payable(order.seller).call{value: AFTtoWEI(order.remained_AFT, order.price)}("");
                require(sent, "Failed to send Ether");                
                
                buy_list[i].remained_AFT -= order.remained_AFT;
                market_total_offers -= order.remained_AFT;
                market_total_requests -= order.remained_AFT;
                order.finished_time = block.timestamp;
                print_sell_completion(order);
                completed_sell_list.push(order);
                return 0;
            }
            else if (buy_list[i].remained_AFT == order.remained_AFT){

                AFT_token.transfer(buy_list[i].buyer, order.remained_AFT);

                (bool sent, bytes memory data) = payable(order.seller).call{value: AFTtoWEI(order.remained_AFT, order.price)}("");
                require(sent, "Failed to send Ether");                
                
                market_total_requests -= order.remained_AFT;
                market_total_offers -= order.remained_AFT;
                order.finished_time = block.timestamp;
                buy_list[i].finished_time = block.timestamp;
                print_buy_completion(buy_list[i]);
                print_sell_completion(order);
                completed_buy_list.push(buy_list[i]);
                completed_sell_list.push(order);
                buy_list[i].is_done = true;
                return 0;
            }
            else { // if (buy_list[i].remained_AFT < order.remained_AFT)

                AFT_token.transfer(buy_list[i].buyer, buy_list[i].remained_AFT);
                (bool sent, bytes memory data) = payable(order.seller).call{value: AFTtoWEI(buy_list[i].remained_AFT, order.price)}("");
                require(sent, "Failed to send Ether");               
                market_total_offers -= buy_list[i].remained_AFT;                
                market_total_requests -= buy_list[i].remained_AFT;
                order.remained_AFT -= buy_list[i].remained_AFT;
                buy_list[i].finished_time = block.timestamp;
                print_buy_completion(buy_list[i]);
                completed_buy_list.push(buy_list[i]);
                buy_list[i].is_done = true;
            }
            

            if (order.remained_AFT == 0){  // the order is filled
                print_sell_completion(order);
                return 0;
            }
        }
        return order.remained_AFT;
    }

    function print_sell_log(SELL memory order) public pure{

        console.log("\nThe order #", order.orderID);
        console.log("For wallet <", order.seller, "> ");
        console.log("With selling a balance of ", order.payed_AFT, " AFT,");
        console.log("Worth of: ", order.equivalent_ETH, " WEI");
        console.log("LOG: Order creation: ", order.created_time,"\n\n");
    }

    function print_buy_log(BUY memory order) public pure{

        console.log("\nThe order #", order.orderID);
        console.log("For wallet <", order.buyer, "> ");
        console.log("With buying a balance of ", order.equivalent_AFT, " AFT,");
        console.log("Paying: ", order.payed_ETH, " WEI");
        console.log("LOG: Order creation: ", order.created_time,"\n\n");
    }

    function print_buy_creation(BUY memory order) public pure{

        console.log("\n------------------CREATION: ------------------");
        console.log("\nCREATION: ");
        print_buy_log(order);
    }

    function print_sell_creation(SELL memory order) public pure{

        console.log("\n------------------CREATION: ------------------");
        print_sell_log(order);
    }

    function print_buy_completion(BUY memory order) public pure{

        console.log("\n------------------COMPLETED:------------------- ");
        print_buy_log(order);
    }

    function print_sell_completion(SELL memory order) public pure{

        console.log("\n------------------COMPLETED:------------------- ");
        print_sell_log(order);
    }

    function print_completed_buys() public view{

        for (uint256 i=0; i<completed_buy_list.length; i++){
            console.log("\nCompleted: ");
            print_buy_log(completed_buy_list[i]);
            console.log("Finished at: ", completed_buy_list[i].finished_time,"\n\n");
        }
    }

    function print_completed_sells() public view{

        for (uint256 i=0; i<completed_sell_list.length; i++){
            console.log("\nCompleted: ");
            print_sell_log(completed_sell_list[i]);
            console.log("Finished at: ", completed_sell_list[i].finished_time,"\n\n");
        }
    }

    function WEItoAFT_with_profit(uint256 _amount, uint256 price) public pure returns (uint256 out){
        uint256 market_percentage = 3;   // 0.3%
        _amount = _amount * (1000-market_percentage) / 1000;
        return _amount / price;
    }

    function AFTtoWEI_with_profit(uint256 _amount, uint256 price) public pure returns (uint256 out){
        uint256 market_percentage = 3;  // 0.3%
        _amount = _amount * (1000-market_percentage) / 1000;
        return _amount * price;
    }

    function AFTtoWEI(uint256 _amount, uint256 price) public pure returns (uint256 out){

        return _amount * price;
    }

    function WEItoAFT(uint256 _amount, uint256 price) public pure returns (uint256 out){

        return _amount / price;
    }
}
