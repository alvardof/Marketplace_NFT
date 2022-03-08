const { expect } = require("chai");

describe("Token contract", function () {
  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("TokenERC1155");

    const hardhatToken = await Token.deploy();

    await hardhatToken.initialize(["QmcLkFCxE4fsqUZei9LqCNnUgq3EP6WUgBLNVXcDhww828", "QmcLkFCxE4fsqUZei9LqCNnUgq3EP6WUgBLNVXcDhww828"], {from: owner.address});
    //expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
  });
});








/*const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});*/
