require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Treasury...");
  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.deploy();

  await treasury.deployed();
  console.log("Treasury deployed to:", treasury.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });