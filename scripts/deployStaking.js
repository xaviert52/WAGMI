require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const stakingTokenAddress = process.env.STAKING_TOKEN_ADDRESS;
  const initialOwner = process.env.INITIAL_OWNER;
  const maxStake = ethers.utils.parseEther("10000"); // Máximo de stake permitido para todos los usuarios
  const lockPeriods = [30 * 24 * 60 * 60, 90 * 24 * 60 * 60, 180 * 24 * 60 * 60, 365 * 24 * 60 * 60];
  const rewardRates = [5, 10, 15, 20];
  const earlyWithdrawalPenalties = [20, 15, 10, 5];

  if (!stakingTokenAddress || !initialOwner) {
    throw new Error("Please set STAKING_TOKEN_ADDRESS and INITIAL_OWNER in your .env file");
  }

  console.log("Deploying StakingContract...");
  const StakingContract = await ethers.getContractFactory("StakingContract");
  const stakingContract = await StakingContract.deploy(
    stakingTokenAddress,
    initialOwner,
    maxStake,
    lockPeriods,
    rewardRates,
    earlyWithdrawalPenalties
  );

  await stakingContract.deployed();
  console.log("StakingContract deployed to:", stakingContract.address);

  // Guardar la dirección del contrato en el archivo .env
  const envPath = "./.env";
  fs.appendFileSync(envPath, `STAKING_CONTRACT_ADDRESS=${stakingContract.address}\n`);
  console.log(`STAKING_CONTRACT_ADDRESS saved to ${envPath}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });