require("dotenv").config();
const { ethers } = require("hardhat");

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

  // Assign EXECUTOR_ROLE to the TimelockController itself
  console.log("Assigning EXECUTOR_ROLE to TimelockController...");
  const EXECUTOR_ROLE = await timelock.EXECUTOR_ROLE();
  await timelock.grantRole(EXECUTOR_ROLE, timelock.address);
  console.log("EXECUTOR_ROLE assigned to TimelockController.");

  // Revoke admin role from the deployer
  console.log("Revoking admin role from deployer...");
  const TIMELOCK_ADMIN_ROLE = await timelock.TIMELOCK_ADMIN_ROLE();
  await timelock.revokeRole(TIMELOCK_ADMIN_ROLE, await ethers.provider.getSigner().getAddress());
  console.log("Admin role revoked.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });