const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StakingContract", function () {
  let StakingContract, stakingContract, stakingToken, owner, user1, user2;
  const initialSupply = ethers.utils.parseEther("1000000"); // 1,000,000 tokens
  const maxStakePerUser = ethers.utils.parseEther("1000"); // 1,000 tokens
  const earlyWithdrawalPenalty = 10; // 10%
  const lockPeriods = [30 * 24 * 60 * 60, 90 * 24 * 60 * 60, 180 * 24 * 60 * 60, 365 * 24 * 60 * 60]; // Lock periods in seconds
  const rewardRates = [5, 10, 15, 20]; // Reward rates in percentage (5%, 10%, etc.)

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
      maxStakePerUser,
      earlyWithdrawalPenalty,
      lockPeriods,
      rewardRates
    );
    await stakingContract.deployed();

    // Approve staking contract to spend tokens
    await stakingToken.connect(owner).transfer(user1.address, ethers.utils.parseEther("1000"));
    await stakingToken.connect(owner).transfer(user2.address, ethers.utils.parseEther("1000"));
    await stakingToken.connect(user1).approve(stakingContract.address, ethers.utils.parseEther("1000"));
    await stakingToken.connect(user2).approve(stakingContract.address, ethers.utils.parseEther("1000"));
  });

  it("should initialize with the correct values", async function () {
    expect(await stakingContract.stakingToken()).to.equal(stakingToken.address);
    expect(await stakingContract.maxStakePerUser()).to.equal(maxStakePerUser);
    expect(await stakingContract.earlyWithdrawalPenalty()).to.equal(earlyWithdrawalPenalty);

    for (let i = 0; i < lockPeriods.length; i++) {
      const plan = await stakingContract.stakingPlans(i);
      expect(plan.lockPeriod).to.equal(lockPeriods[i]);
      expect(plan.rewardRate).to.equal(rewardRates[i]);
    }
  });

  it("should allow users to stake tokens", async function () {
    const amount = ethers.utils.parseEther("500");
    await expect(stakingContract.connect(user1).stake(amount, 0))
      .to.emit(stakingContract, "Staked")
      .withArgs(user1.address, amount, 0);

    const userTotalStake = await stakingContract.getUserTotalStake(user1.address);
    expect(userTotalStake).to.equal(amount);
  });

  it("should not allow staking more than the maximum allowed per user", async function () {
    const amount = ethers.utils.parseEther("1500"); // Exceeds maxStakePerUser
    await expect(stakingContract.connect(user1).stake(amount, 0)).to.be.revertedWith(
      "Stake exceeds maximum allowed per user"
    );
  });

  it("should allow users to withdraw tokens with rewards after lock period", async function () {
    const amount = ethers.utils.parseEther("500");
    const planIndex = 0; // 30 days lock period
    await stakingContract.connect(user1).stake(amount, planIndex);

    // Simulate time passing
    await ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]); // 30 days
    await ethers.provider.send("evm_mine");

    const userBalanceBefore = await stakingToken.balanceOf(user1.address);
    await expect(stakingContract.connect(user1).withdraw(0))
      .to.emit(stakingContract, "Withdrawn")
      .withArgs(user1.address, amount, ethers.utils.parseEther("2.054794520547945205")); // Reward calculated

    const userBalanceAfter = await stakingToken.balanceOf(user1.address);
    expect(userBalanceAfter.sub(userBalanceBefore)).to.be.closeTo(
      amount.add(ethers.utils.parseEther("2.054794520547945205")),
      ethers.utils.parseEther("0.000000000000000001")
    );
  });

  it("should apply penalty for early withdrawal", async function () {
    const amount = ethers.utils.parseEther("500");
    const planIndex = 1; // 90 days lock period
    await stakingContract.connect(user1).stake(amount, planIndex);

    // Simulate time passing (less than lock period)
    await ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]); // 30 days
    await ethers.provider.send("evm_mine");

    const userBalanceBefore = await stakingToken.balanceOf(user1.address);
    await expect(stakingContract.connect(user1).withdraw(0))
      .to.emit(stakingContract, "EarlyWithdrawal")
      .withArgs(user1.address, amount, ethers.utils.parseEther("50")); // 10% penalty

    const userBalanceAfter = await stakingToken.balanceOf(user1.address);
    expect(userBalanceAfter.sub(userBalanceBefore)).to.equal(amount.sub(ethers.utils.parseEther("50"))); // Amount minus penalty
  });

  it("should calculate voting power correctly", async function () {
    const amount = ethers.utils.parseEther("500");
    const planIndex = 3; // 365 days lock period
    await stakingContract.connect(user1).stake(amount, planIndex);

    const votingPower = await stakingContract.getVotingPower(user1.address);
    expect(votingPower).to.equal(amount.mul(2)); // 2x multiplier for 365 days lock period
  });
});
//hardcoded-credentials Embedding credentials in source code risks unauthorized access
