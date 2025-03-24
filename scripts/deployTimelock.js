require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const minDelay = process.env.TIMELOCK_MIN_DELAY || 3600; // 1 hour by default
  const governorAddress = process.env.GOVERNOR_ADDRESS;

  if (!governorAddress) {
    throw new Error("Please set GOVERNOR_ADDRESS in your .env file");
  }

  console.log("Deploying TimelockController...");
  const Timelock = await ethers.getContractFactory("WAGMITimelock");
  const timelock = await Timelock.deploy(minDelay, [governorAddress], []);

  await timelock.deployed();
  console.log("TimelockController deployed to:", timelock.address);

  // Guardar la dirección del contrato en el archivo .env
  const envPath = "./.env";
  fs.appendFileSync(envPath, `TIMELOCK_ADDRESS=${timelock.address}\n`);
  console.log(`TIMELOCK_ADDRESS saved to ${envPath}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });