// SPDX-License-Identifier: MIT


import "hardhat/console.sol";

pragma solidity ^0.8.0;

contract create_voting{

    address owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    string[] public nominates;
    address[] public students;
    mapping (string => uint) public votes;
    mapping (address => bool) public has_voted;
    mapping (address => string) public who_voted_who;
    uint public starting_timestamp;
    uint public ending_timestamp;
    uint public max_voters;
    uint public voters_by_now;
    uint public max_vote = 0;
    string public temp_winner = "";


    modifier onlyOwner(){
        require(msg.sender == owner, "You don't have the authority of admin.");
        _;
    }

    modifier onlyStudent(){
        require(is_student_already_signedup(msg.sender), "You are not authorized as student.");
        _;
    }

    function is_student_already_signedup(address student) public view returns(bool b){

        for (uint i=0; i<students.length; i++){
            if(students[i] == student){
                return true;
            }
        }
        return false;
    }

    function add_students(address[] memory s) public onlyOwner{

        if(s.length + students.length > max_voters){
            console.log("The number of voters has exceeded the maximum. ABORT.");
            return;
        }

        for(uint i=0; i<s.length; i++){

            if(is_student_already_signedup(s[i])){
                console.log("The student ",s[i]," has already been signed up. ABORT.");
                return;
            }
        }

        for(uint i=0; i<s.length; i++){

            students.push(s[i]);
        }
    }

    function delay_election(uint time) public onlyOwner{

        ending_timestamp += time;
        console.log("The election has been delayed for ",time," seconds.");
        return;
    }

    function create_election(string[] memory nominate, uint max_num_of_voters) public onlyOwner{

        nominates = nominate;
        starting_timestamp = block.timestamp;
        ending_timestamp = starting_timestamp + 600;
        max_voters = max_num_of_voters;
        voters_by_now = 0;
    }

    function change_vote(string memory nominate) public onlyStudent{

        if (has_voted[msg.sender] == false){
            console.log("You must vote first.");
            return;
        }

        string memory early_nominate = who_voted_who[msg.sender];
        votes[early_nominate]--;
        who_voted_who[msg.sender] = nominate;
        votes[nominate]++;
        if(votes[nominate] > max_vote){
            max_vote = votes[nominate];
            temp_winner = nominate;
        }
    }

    function set_winner() public view onlyOwner{

        if(block.timestamp < ending_timestamp){
            console.log("The election has not finished yet.");
            return;
        }
        if(voters_by_now < students.length / 2){
            console.log("The election has been canceled due to lack of participation");
            return;
        }

        for (uint i=0; i<nominates.length; i++){

            string memory nominate = nominates[i];
            if (keccak256(abi.encodePacked(nominate)) != keccak256(abi.encodePacked(temp_winner)) && votes[nominate] == max_vote){
                console.log("No_WINNER");
                return;
            }
        }

        console.log(temp_winner);
        return;
    }

    function vote(string memory nominate) public onlyStudent{

        if (block.timestamp > ending_timestamp){
            console.log("The election is closed.");
            return;
        }

        if (has_voted[msg.sender] == true){
            console.log("You cannot vote twice.");
            return;
        }

        votes[nominate]++;
        if(votes[nominate] > max_vote){
            max_vote = votes[nominate];
            temp_winner = nominate;
        }
        has_voted[msg.sender] = true;
        who_voted_who[msg.sender] = nominate;
        voters_by_now++;
    }

}