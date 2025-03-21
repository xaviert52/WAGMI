require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  const minDelay = process.env.TIMELOCK_MIN_DELAY || 3600; // 1 hora por defecto
  const governorAddress = process.env.GOVERNOR_ADDRESS; // Dirección del contrato Governor

  if (!governorAddress) {
    throw new Error("Please set GOVERNOR_ADDRESS in your .env file");
  }

  console.log("Deploying TimelockController...");
  const Timelock = await ethers.getContractFactory("WAGMITimelock");
  const timelock = await Timelock.deploy(minDelay, [governorAddress], [timelock.address]); // Asignar EXECUTOR_ROLE al TimelockController

  await timelock.deployed();
  console.log("TimelockController deployed to:", timelock.address);

  // Revocar el rol de administrador del TimelockController
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