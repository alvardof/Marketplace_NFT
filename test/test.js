const { expect } = require("chai");


describe("Token contract", function () {
  it("contract deployment ", async function () {
    const [owner] = await ethers.getSigners();

    const dai = await ethers.getContractFactory("DAI");
    const link = await ethers.getContractFactory("LINK");
    const NFTMarket = await ethers.getContractFactory("NFTMarket");

    const dai_ = await dai.deploy();

    const link_ = await link.deploy();

    const hardhatNFTMarke = await NFTMarket.deploy();

    await hardhatNFTMarke.initialize(dai_.address , link_.address, {from: owner.address});



  });

});








