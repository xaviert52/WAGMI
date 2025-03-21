require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  // Load environment variables
  const stakingTokenAddress = process.env.STAKING_TOKEN_ADDRESS; // Address of the staking token (WAGMIToken)
  const maxStakePerUser = process.env.MAX_STAKE_PER_USER || ethers.utils.parseEther("1000"); // Default: 1000 tokens
  const earlyWithdrawalPenalty = process.env.EARLY_WITHDRAWAL_PENALTY || 10; // Default: 10% penalty
  const lockPeriods = [30 * 24 * 60 * 60, 90 * 24 * 60 * 60, 180 * 24 * 60 * 60, 365 * 24 * 60 * 60]; // Lock periods in seconds
  const rewardRates = [5, 10, 15, 20]; // Reward rates in percentage (5%, 10%, etc.)

  // Validate environment variables
  if (!stakingTokenAddress) {
    throw new Error("Please set STAKING_TOKEN_ADDRESS in your .env file");
  }

  console.log("Deploying StakingContract...");
  console.log("Staking Token Address:", stakingTokenAddress);
  console.log("Max Stake Per User:", ethers.utils.formatEther(maxStakePerUser), "tokens");
  console.log("Early Withdrawal Penalty:", earlyWithdrawalPenalty, "%");
  console.log("Lock Periods (days):", lockPeriods.map((p) => p / (24 * 60 * 60)));
  console.log("Reward Rates (%):", rewardRates);

  // Get the contract factory
  const StakingContract = await ethers.getContractFactory("StakingContract");

  // Deploy the contract
  const stakingContract = await StakingContract.deploy(
    stakingTokenAddress,
    maxStakePerUser,
    earlyWithdrawalPenalty,
    lockPeriods,
    rewardRates
  );

  // Wait for the deployment to complete
  await stakingContract.deployed();

  console.log("StakingContract deployed to:", stakingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });