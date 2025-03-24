require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const stakingAddress = process.env.STAKING_CONTRACT_ADDRESS;
  const timelockAddress = process.env.TIMELOCK_ADDRESS;

  if (!stakingAddress || !timelockAddress) {
    throw new Error("Please set STAKING_CONTRACT_ADDRESS and TIMELOCK_ADDRESS in your .env file");
  }

  console.log("Deploying Governor...");
  const Governor = await ethers.getContractFactory("WAGMIGovernor");
  const governor = await Governor.deploy(stakingAddress, timelockAddress);

  await governor.deployed();
  console.log("Governor deployed to:", governor.address);

  // Guardar la dirección del contrato en el archivo .env
  const envPath = "./.env";
  fs.appendFileSync(envPath, `GOVERNOR_ADDRESS=${governor.address}\n`);
  console.log(`GOVERNOR_ADDRESS saved to ${envPath}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });