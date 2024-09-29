# This is a market for AFT token (Amir's First Token)!

![image](https://img.shields.io/badge/Solidity-e6e6e6?style=for-the-badge&logo=solidity&logoColor=black)  ![image](https://img.shields.io/badge/Ethereum-3C3C3D?style=for-the-badge&logo=Ethereum&logoColor=white) 

**This means you can place orders for selling and buying AFT with your own price;**
**The market will match the orders together and pay you with the currency that you want!**

There are some steps to take:

 **1-** Deploy the AmirERC20 contract as the owner of the token (W1: owner wallet, C1: wallet of the contract itself)

 
 **2-** Deploy the market contract as the owner of the market (W2: owner wallet, C2: wallet of the market itself)

 
 **3-** Give credit as W1 to C2:
 
     - use transfer function in C1 to give the amount of AFT that you want to C2

     
 **4-** Now you can place buy orders! 

 
 **5-** before selling, there is one more step:
 
     - as seller, you should allow the market to spend your AFTs and run this: C1.approve(C2, num_of_AFT)
     
     - Then you can place your selling order with amount of AFT that you want (<= num_of_AFT)
