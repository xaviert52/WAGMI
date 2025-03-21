const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("WAGMIToken", function () {
  let WAGMIToken, wagmiToken, owner, treasury, user1, user2;

  beforeEach(async function () {
    [owner, treasury, user1, user2] = await ethers.getSigners();

    // Deploy the WAGMIToken contract
    WAGMIToken = await ethers.getContractFactory("WAGMI");
    wagmiToken = await upgrades.deployProxy(WAGMIToken, [owner.address, treasury.address], {
      initializer: "initialize",
    });
    await wagmiToken.deployed();
  });

  it("should initialize with the correct values", async function () {
    expect(await wagmiToken.name()).to.equal("We All Gonna Make It");
    expect(await wagmiToken.symbol()).to.equal("WAGMI");
    expect(await wagmiToken.totalSupply()).to.equal(ethers.utils.parseEther("10000000")); // 10 million tokens
    expect(await wagmiToken.treasuryAddress()).to.equal(treasury.address);
  });

  it("should allow the owner to update the fee structure", async function () {
    await wagmiToken.setFeeStructure(2, 3); // 2% burn fee, 3% treasury fee
    expect(await wagmiToken.burnFee()).to.equal(2);
    expect(await wagmiToken.treasuryFee()).to.equal(3);
    expect(await wagmiToken.totalFee()).to.equal(5);
  });

  it("should revert if total fee exceeds 100%", async function () {
    await expect(wagmiToken.setFeeStructure(50, 51)).to.be.revertedWith("Total fee cannot exceed 100%");
  });

  it("should allow the owner to set fee exemptions", async function () {
    await wagmiToken.setFeeExemption(user1.address, true);
    expect(await wagmiToken.feeExempt(user1.address)).to.be.true;

    await wagmiToken.setFeeExemption(user1.address, false);
    expect(await wagmiToken.feeExempt(user1.address)).to.be.false;
  });

  it("should apply fees correctly during transfers", async function () {
    // Set fees: 1% burn fee, 1% treasury fee
    await wagmiToken.setFeeStructure(1, 1);

    // Transfer tokens from owner to user1
    const transferAmount = ethers.utils.parseEther("1000");
    await wagmiToken.transfer(user1.address, transferAmount);

    // User1 transfers tokens to user2
    const user1TransferAmount = ethers.utils.parseEther("100");
    await wagmiToken.connect(user1).transfer(user2.address, user1TransferAmount);

    // Check balances
    const burnAmount = user1TransferAmount.mul(1).div(100); // 1% burn fee
    const treasuryAmount = user1TransferAmount.mul(1).div(100); // 1% treasury fee
    const netAmount = user1TransferAmount.sub(burnAmount).sub(treasuryAmount);

    expect(await wagmiToken.balanceOf(user2.address)).to.equal(netAmount);
    expect(await wagmiToken.balanceOf(treasury.address)).to.equal(treasuryAmount);
    expect(await wagmiToken.totalSupply()).to.equal(
      ethers.utils.parseEther("10000000").sub(burnAmount) // Total supply reduced by burn amount
    );
  });

  it("should not apply fees for fee-exempt addresses", async function () {
    // Set fees: 1% burn fee, 1% treasury fee
    await wagmiToken.setFeeStructure(1, 1);

    // Exempt user1 from fees
    await wagmiToken.setFeeExemption(user1.address, true);

    // Transfer tokens from user1 to user2
    const transferAmount = ethers.utils.parseEther("100");
    await wagmiToken.transfer(user1.address, transferAmount);
    await wagmiToken.connect(user1).transfer(user2.address, transferAmount);

    // Check balances
    expect(await wagmiToken.balanceOf(user2.address)).to.equal(transferAmount);
    expect(await wagmiToken.balanceOf(treasury.address)).to.equal(0); // No treasury fee
    expect(await wagmiToken.totalSupply()).to.equal(ethers.utils.parseEther("10000000")); // No burn fee
  });

  it("should allow the owner to pause and unpause transfers", async function () {
    await wagmiToken.pause();
    await expect(wagmiToken.transfer(user1.address, ethers.utils.parseEther("100"))).to.be.revertedWith(
      "Token transfers are paused"
    );

    await wagmiToken.unpause();
    await expect(wagmiToken.transfer(user1.address, ethers.utils.parseEther("100"))).to.not.be.reverted;
  });

  it("should allow receiving ETH", async function () {
    const sendValue = ethers.utils.parseEther("1");
    await owner.sendTransaction({ to: wagmiToken.address, value: sendValue });

    const contractBalance = await ethers.provider.getBalance(wagmiToken.address);
    expect(contractBalance).to.equal(sendValue);
  });
});