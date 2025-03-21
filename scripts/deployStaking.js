require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  const stakingTokenAddress = process.env.STAKING_TOKEN_ADDRESS;
  const maxStakePerUser = process.env.MAX_STAKE_PER_USER || ethers.utils.parseEther("1000");
  const maxStakePerWhale = ethers.utils.parseEther("100000"); // Restricción para ballenas
  const lockPeriods = [30 * 24 * 60 * 60, 90 * 24 * 60 * 60, 180 * 24 * 60 * 60, 365 * 24 * 60 * 60];
  const rewardRates = [5, 10, 15, 20];
  const earlyWithdrawalPenalties = [20, 15, 10, 5]; // Penalizaciones específicas para cada plan

  if (!stakingTokenAddress) {
    throw new Error("Please set STAKING_TOKEN_ADDRESS in your .env file");
  }

  console.log("Deploying StakingContract...");
  const StakingContract = await ethers.getContractFactory("StakingContract");
  const stakingContract = await StakingContract.deploy(
    stakingTokenAddress,
    maxStakePerUser,
    maxStakePerWhale,
    lockPeriods,
    rewardRates,
    earlyWithdrawalPenalties
  );

  await stakingContract.deployed();
  console.log("StakingContract deployed to:", stakingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });