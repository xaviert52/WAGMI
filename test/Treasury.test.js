const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Treasury", function () {
  let Treasury, treasury, owner;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    Treasury = await ethers.getContractFactory("Treasury");
    treasury = await Treasury.deploy();
    await treasury.deployed();
  });

  it("should receive funds", async function () {
    const amount = ethers.utils.parseEther("1");
    await owner.sendTransaction({ to: treasury.address, value: amount });
    expect(await treasury.getBalance()).to.equal(amount);
  });
});