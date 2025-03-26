const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StakingContract", function () {
  let StakingContract, stakingContract, stakingToken, owner, user1, user2;
  const initialSupply = ethers.utils.parseEther("10000000"); // 10,000,000 tokens
  const maxStake = ethers.utils.parseEther("10000"); // Máximo de stake permitido para todos los usuarios
  const lockPeriods = [30 * 24 * 60 * 60, 90 * 24 * 60 * 60, 180 * 24 * 60 * 60, 365 * 24 * 60 * 60];
  const rewardRates = [5, 10, 15, 20];
  const earlyWithdrawalPenalties = [20, 15, 10, 5];

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy a mock ERC20 token for staking
    const Token = await ethers.getContractFactory("ERC20Mock");
    stakingToken = await Token.deploy("Staking Token", "STK", owner.address, initialSupply);
    await stakingToken.deployed();

    // Deploy the StakingContract
    const Staking = await ethers.getContractFactory("StakingContract");
    stakingContract = await Staking.deploy(
      stakingToken.address,
      owner.address,
      maxStake,
      lockPeriods,
      rewardRates,
      earlyWithdrawalPenalties
    );
    await stakingContract.deployed();

    // Approve staking contract to spend tokens
    await stakingToken.connect(owner).transfer(user1.address, ethers.utils.parseEther("1000"));
    await stakingToken.connect(owner).transfer(user2.address, ethers.utils.parseEther("1000"));
    await stakingToken.connect(user1).approve(stakingContract.address, ethers.utils.parseEther("1000"));
    await stakingToken.connect(user2).approve(stakingContract.address, ethers.utils.parseEther("1000"));

    // Add funds to the reward pool
    await stakingToken.connect(owner).approve(stakingContract.address, ethers.utils.parseEther("100000"));
    await stakingContract.addRewardPool(ethers.utils.parseEther("100000"));
  });

  it("should calculate dynamic penalties for early withdrawals", async function () {
    const stakeAmount = ethers.utils.parseEther("500");
    const planIndex = 3; // 365 days lock period

    await stakingContract.connect(user1).stake(stakeAmount, planIndex);

    // Simulate time passing (25% of lock period)
    await ethers.provider.send("evm_increaseTime", [91 * 24 * 60 * 60]); // ~91 days
    await ethers.provider.send("evm_mine");

    const rewardPoolBefore = await stakingContract.rewardPool();
    await stakingContract.connect(user1).withdraw(0);
    const rewardPoolAfter = await stakingContract.rewardPool();

    expect(rewardPoolAfter).to.be.greaterThan(rewardPoolBefore); // Penalty added to reward pool
  });

  it("should revert if reward pool has insufficient funds", async function () {
    const stakeAmount = ethers.utils.parseEther("500");
    const planIndex = 3; // 365 days lock period

    await stakingContract.connect(user1).stake(stakeAmount, planIndex);

    // Deplete the reward pool
    await stakingContract.connect(owner).accessLockedFunds(ethers.utils.parseEther("100000"));

    // Simulate time passing
    await ethers.provider.send("evm_increaseTime", [365 * 24 * 60 * 60]); // 365 days
    await ethers.provider.send("evm_mine");

    await expect(stakingContract.connect(user1).withdraw(0)).to.be.revertedWith("Insufficient reward pool");
  });

  it("should allow the DAO to access up to 30% of locked funds", async function () {
    const stakeAmount = ethers.utils.parseEther("1000");
    const planIndex = 3; // 365 days lock period

    await stakingContract.connect(user1).stake(stakeAmount, planIndex);

    const maxAllowed = (await stakingContract.totalStaked()).mul(30).div(100);
    await expect(stakingContract.connect(owner).accessLockedFunds(maxAllowed)).to.not.be.reverted;
  });
});