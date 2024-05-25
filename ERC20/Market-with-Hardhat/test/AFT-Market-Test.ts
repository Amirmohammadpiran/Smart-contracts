import { expect } from "chai";
import { ethers } from "hardhat";
import { AFT_Market, AmirERC20 } from "../typechain-types";
import { Signer } from "ethers";


describe("AFT-Market Tests", function () {

  let AFT: AmirERC20;
  let Market: AFT_Market;
  let Market_address: string;
  let AFT_owner : Signer;
  let Market_owner : Signer;
  let seller1 : Signer;
  let seller2 : Signer;

    before(async function () {

      [AFT_owner, Market_owner, seller1, seller2] = await ethers.getSigners();

      AFT = await ethers.deployContract("AmirERC20", AFT_owner);
      
      Market = await ethers.deployContract("AFT_Market", Market_owner);
      const AFT_address = (await AFT.getAddress()).toLowerCase();
      Market_address = (await Market.getAddress()).toLowerCase();
      await Market.connect(Market_owner).assign_token(AFT_address);
      
      await AFT.connect(AFT_owner).transfer(Market_address, 100000000000);


      // giving tokens to the sellers for testing:
      await AFT.connect(AFT_owner).transfer(seller1, 10000000);
      await AFT.connect(AFT_owner).transfer(seller2, 20000000);

    });

    describe("After Deployment", function (){
      
      it("Deployment should assign the total supply of AFT tokens to the market", async function () {
      
        expect(await Market.connect(Market_owner).token_balance()).to.equal(100000000000);
      });

      it("sellers should have enough AFT balance", async function () {
    
        expect(await Market.connect(seller1).user_AFT_balance()).to.equal(10000000);
        expect(await Market.connect(seller2).user_AFT_balance()).to.equal(20000000);
      });
    });

    describe("Market Testing", function (){
      
      it("Users should be able to buy tokens", async function () {

        const buyer1_address = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8".toLowerCase();  // has enough ETH
        const buyer1 = await ethers.getSigner(buyer1_address);
        const spent_WEI = await Market.connect(buyer1).AFTtoWEI(100, 1000);  // wanted to buy 100 AFT
        const amountToSend = ethers.formatUnits(spent_WEI, "wei");
    
        await Market.connect(buyer1).BuyAFT(1000, {
          value: amountToSend
        });
    
        expect(await ethers.provider.getBalance(Market)).to.equal(amountToSend);
      });


      it("Users should be able to sell tokens", async function () {
          
        await AFT.connect(seller1).approve(Market_address, 2000);
        await Market.connect(seller1).SellAFT(2000, 1000);

        expect(await Market.connect(Market_owner).token_balance()).to.equal(100000001901);  // 100000000000 + 2000 - 99
    });

  });

})
