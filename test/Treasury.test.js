const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Treasury", function () {
  let Treasury, treasury, owner, recipient;
  const category = ethers.utils.formatBytes32String("ecosystem");

  beforeEach(async function () {
    [owner, recipient] = await ethers.getSigners();
    Treasury = await ethers.getContractFactory("Treasury");
    treasury = await Treasury.deploy(owner.address);
    await treasury.deployed();

    // Add a valid category
    await treasury.addCategory(category);
  });

  it("should allow adding and removing categories", async function () {
    const newCategory = ethers.utils.formatBytes32String("community");
    await treasury.addCategory(newCategory);
    expect(await treasury.allowedCategories(newCategory)).to.be.true;

    await treasury.removeCategory(newCategory);
    expect(await treasury.allowedCategories(newCategory)).to.be.false;
  });

  it("should track usage of funds by category", async function () {
    const amount = ethers.utils.parseEther("1");
    await owner.sendTransaction({ to: treasury.address, value: amount });

    await treasury.allocateFunds(category, amount);
    await treasury.transferFunds(category, recipient.address, amount);

    expect(await treasury.categoryUsage(category)).to.equal(amount);
  });

  it("should revert if transferring to an invalid category", async function () {
    const invalidCategory = ethers.utils.formatBytes32String("invalid");
    const amount = ethers.utils.parseEther("1");

    await expect(treasury.transferFunds(invalidCategory, recipient.address, amount)).to.be.revertedWith(
      "Invalid category"
    );
  });
});