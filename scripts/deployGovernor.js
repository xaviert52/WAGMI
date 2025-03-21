require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  const tokenAddress = process.env.TOKEN_ADDRESS;
  const timelockAddress = process.env.TIMELOCK_ADDRESS;

  if (!tokenAddress || !timelockAddress) {
    throw new Error("Please set TOKEN_ADDRESS and TIMELOCK_ADDRESS in your .env file");
  }

  console.log("Deploying Governor...");
  const Governor = await ethers.getContractFactory("WAGMIGovernor");
  const governor = await Governor.deploy(tokenAddress, timelockAddress);

  await governor.deployed();
  console.log("Governor deployed to:", governor.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });