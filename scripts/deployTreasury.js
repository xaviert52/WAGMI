require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const initialOwner = process.env.INITIAL_OWNER;

  if (!initialOwner) {
    throw new Error("Please set INITIAL_OWNER in your .env file");
  }

  console.log("Deploying Treasury...");
  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.deploy(initialOwner);

  await treasury.deployed();
  console.log("Treasury deployed to:", treasury.address);

  // Guardar la dirección del contrato en el archivo .env
  const envPath = "./.env";
  fs.appendFileSync(envPath, `TREASURY_ADDRESS=${treasury.address}\n`);
  console.log(`TREASURY_ADDRESS saved to ${envPath}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });