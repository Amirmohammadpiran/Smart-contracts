// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test{

    int[] signeddarr = [-1, 5];
    uint[] unsignedarr = [1, 2];

    bytes7 b =  "V";

    enum e {a, b, c}
    
    int a = 0;

    struct student {
         string name;
         uint id;
         bool isgraduated;
    }

    student s = student("amir", 123, false);

    
}

contract mappings {

     mapping(string => uint) public map;

     function additem (string memory key, uint value) public {
         map[key] = value;
     }

     function getitem (string memory key)  public view returns (uint value){

         return map[key];
     }

     function deleteitem (string memory key) public {
        delete map[key];
     }
}

contract testloop {

    uint[] nums;

    function assignnums(uint[] memory numbers) public {

        nums = numbers;
        return;
    }

    function sumnums() public view returns (uint sum){

        uint sum = 0;
        for (uint i=0; i<nums.length; i++){
            sum += nums[i];
        }
        return sum;
    }
}

contract modify{

    address owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    function add(uint a, uint b) onlyOwner public view returns (uint sum){
        return a+b;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "U ain't tha bloody owner");
        _;
    }
}