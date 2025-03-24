const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GovernorContract", function () {
  let Governor, governor, StakingContract, stakingContract, stakingToken, owner, user1, user2;
  const initialSupply = ethers.utils.parseEther("1000000"); // 1,000,000 tokens
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

    // Deploy the GovernorContract
    const GovernorFactory = await ethers.getContractFactory("WAGMIGovernor");
    governor = await GovernorFactory.deploy(stakingContract.address, owner.address);
    await governor.deployed();

    // Approve staking contract to spend tokens
    await stakingToken.connect(owner).transfer(user1.address, ethers.utils.parseEther("1000"));
    await stakingToken.connect(user1).approve(stakingContract.address, ethers.utils.parseEther("1000"));
  });

  it("should calculate voting power correctly based on stakes", async function () {
    const stakeAmount = ethers.utils.parseEther("500");
    const planIndex = 3; // 365 days lock period

    await stakingContract.connect(user1).stake(stakeAmount, planIndex);

    const votingPower = await governor.getVotes(user1.address, 0);
    expect(votingPower).to.equal(stakeAmount.mul(2)); // 2x multiplier for 365 days lock period
  });

  it("should revert if a user without voting power tries to create a proposal", async function () {
    const targets = [stakingContract.address];
    const values = [0];
    const calldatas = [stakingContract.interface.encodeFunctionData("stake", [100, 0])];
    const description = "Test Proposal";

    await expect(
      governor.connect(user2).propose(targets, values, calldatas, description)
    ).to.be.revertedWith("Governor: proposer votes below proposal threshold");
  });

  it("should allow a user with sufficient voting power to create a proposal", async function () {
    const stakeAmount = ethers.utils.parseEther("500");
    const planIndex = 3; // 365 days lock period

    await stakingContract.connect(user1).stake(stakeAmount, planIndex);

    const targets = [stakingContract.address];
    const values = [0];
    const calldatas = [stakingContract.interface.encodeFunctionData("stake", [100, 0])];
    const description = "Test Proposal";

    await expect(governor.connect(user1).propose(targets, values, calldatas, description))
      .to.emit(governor, "ProposalCreated");
  });
});