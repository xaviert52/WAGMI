const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("WAGMITimelock", function () {
  let Timelock, timelock, owner, proposer, executor, other;

  beforeEach(async function () {
    [owner, proposer, executor, other] = await ethers.getSigners();

    // Deploy the WAGMITimelock contract
    const minDelay = 3600; // 1 hour delay
    const proposers = [proposer.address];
    const executors = [executor.address];

    Timelock = await ethers.getContractFactory("WAGMITimelock");
    timelock = await Timelock.deploy(minDelay, proposers, executors);
    await timelock.deployed();
  });

  it("should initialize with the correct values", async function () {
    expect(await timelock.getMinDelay()).to.equal(3600); // 1 hour delay
    expect(await timelock.hasRole(await timelock.PROPOSER_ROLE(), proposer.address)).to.be.true;
    expect(await timelock.hasRole(await timelock.EXECUTOR_ROLE(), executor.address)).to.be.true;
    expect(await timelock.hasRole(await timelock.TIMELOCK_ADMIN_ROLE(), owner.address)).to.be.true;
  });

  it("should allow a proposer to schedule an operation", async function () {
    const target = other.address;
    const value = 0;
    const data = "0x";
    const predecessor = ethers.constants.HashZero;
    const salt = ethers.utils.id("test-operation");
    const delay = 3600; // 1 hour delay

    await expect(
      timelock.connect(proposer).schedule(target, value, data, predecessor, salt, delay)
    ).to.emit(timelock, "CallScheduled");
  });

  it("should revert if a non-proposer tries to schedule an operation", async function () {
    const target = other.address;
    const value = 0;
    const data = "0x";
    const predecessor = ethers.constants.HashZero;
    const salt = ethers.utils.id("test-operation");
    const delay = 3600; // 1 hour delay

    await expect(
      timelock.connect(other).schedule(target, value, data, predecessor, salt, delay)
    ).to.be.revertedWith(
      `AccessControl: account ${other.address.toLowerCase()} is missing role ${await timelock.PROPOSER_ROLE()}`
    );
  });

  it("should allow an executor to execute a scheduled operation", async function () {
    const target = other.address;
    const value = 0;
    const data = "0x";
    const predecessor = ethers.constants.HashZero;
    const salt = ethers.utils.id("test-operation");
    const delay = 3600; // 1 hour delay

    // Schedule the operation
    await timelock.connect(proposer).schedule(target, value, data, predecessor, salt, delay);

    // Increase time to simulate the delay
    await ethers.provider.send("evm_increaseTime", [3600]);
    await ethers.provider.send("evm_mine");

    // Execute the operation
    await expect(
      timelock.connect(executor).execute(target, value, data, predecessor, salt)
    ).to.emit(timelock, "CallExecuted");
  });

  it("should revert if trying to execute before the delay has passed", async function () {
    const target = other.address;
    const value = 0;
    const data = "0x";
    const predecessor = ethers.constants.HashZero;
    const salt = ethers.utils.id("test-operation");
    const delay = 3600; // 1 hour delay

    // Schedule the operation
    await timelock.connect(proposer).schedule(target, value, data, predecessor, salt, delay);

    // Try to execute before the delay
    await expect(
      timelock.connect(executor).execute(target, value, data, predecessor, salt)
    ).to.be.revertedWith("TimelockController: operation is not ready");
  });

  it("should allow the admin to update the minimum delay", async function () {
    const newDelay = 7200; // 2 hours delay
    await timelock.connect(owner).updateDelay(newDelay);
    expect(await timelock.getMinDelay()).to.equal(newDelay);
  });

  it("should revert if a non-admin tries to update the minimum delay", async function () {
    const newDelay = 7200; // 2 hours delay
    await expect(timelock.connect(other).updateDelay(newDelay)).to.be.revertedWith(
      `AccessControl: account ${other.address.toLowerCase()} is missing role ${await timelock.TIMELOCK_ADMIN_ROLE()}`
    );
  });

  it("should only allow the TimelockController to execute proposals", async function () {
    const target = other.address;
    const value = 0;
    const data = "0x";
    const predecessor = ethers.constants.HashZero;
    const salt = ethers.utils.id("test-operation");
    const delay = 3600; // 1 hour delay
  
    // Schedule the operation
    await timelock.connect(proposer).schedule(target, value, data, predecessor, salt, delay);
  
    // Increase time to simulate the delay
    await ethers.provider.send("evm_increaseTime", [3600]);
    await ethers.provider.send("evm_mine");
  
    // Try to execute the operation with a non-executor
    await expect(
      timelock.connect(other).execute(target, value, data, predecessor, salt)
    ).to.be.revertedWith("AccessControl: account is missing role EXECUTOR_ROLE");
  
    // Execute the operation with the TimelockController
    await expect(
      timelock.connect(executor).execute(target, value, data, predecessor, salt)
    ).to.emit(timelock, "CallExecuted");
  });
});
//stack-trace-exposure Error messages or stack traces can reveal sensitive details
