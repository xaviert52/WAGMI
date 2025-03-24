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

  it("should update the reward pool correctly when rewards are added", async function () {
    const initialRewardPool = await stakingContract.rewardPool();
    const additionalReward = ethers.utils.parseEther("5000");

    await stakingToken.connect(owner).approve(stakingContract.address, additionalReward);
    await stakingContract.addRewardPool(additionalReward);

    const updatedRewardPool = await stakingContract.rewardPool();
    expect(updatedRewardPool).to.equal(initialRewardPool.add(additionalReward));
  });

  it("should update the reward pool correctly after withdrawals", async function () {
    const stakeAmount = ethers.utils.parseEther("500");
    const planIndex = 0; // 30 days lock period

    await stakingContract.connect(user1).stake(stakeAmount, planIndex);

    // Simulate time passing
    await ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]); // 30 days
    await ethers.provider.send("evm_mine");

    const rewardPoolBefore = await stakingContract.rewardPool();
    await stakingContract.connect(user1).withdraw(0);
    const rewardPoolAfter = await stakingContract.rewardPool();

    expect(rewardPoolAfter).to.be.lessThan(rewardPoolBefore);
  });

  it("should revert if trying to stake with an invalid plan index", async function () {
    const stakeAmount = ethers.utils.parseEther("500");
    const invalidPlanIndex = 10; // Non-existent plan index

    await expect(stakingContract.connect(user1).stake(stakeAmount, invalidPlanIndex)).to.be.revertedWith(
      "Invalid staking plan"
    );
  });

  it("should revert if trying to withdraw more than the staked amount", async function () {
    const stakeAmount = ethers.utils.parseEther("500");
    const planIndex = 0; // 30 days lock period

    await stakingContract.connect(user1).stake(stakeAmount, planIndex);

    // Simulate time passing
    await ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]); // 30 days
    await ethers.provider.send("evm_mine");

    // Attempt to withdraw from an invalid stake index
    await expect(stakingContract.connect(user1).withdraw(1)).to.be.revertedWith("Invalid stake index");
  });
});