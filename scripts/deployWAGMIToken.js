require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const tokenName = "We All Gonna Make It";
  const tokenSymbol = "WAGMI";
  const initialSupply = ethers.utils.parseEther("10000000"); // 10 millones de tokens
  const treasuryAddress = process.env.TREASURY_ADDRESS;
  const initialOwner = process.env.INITIAL_OWNER;

  if (!treasuryAddress || !initialOwner) {
    throw new Error("Please set TREASURY_ADDRESS and INITIAL_OWNER in your .env file");
  }

  console.log("Deploying WAGMIToken...");
  const WAGMIToken = await ethers.getContractFactory("WAGMIToken");
  const wagmiToken = await WAGMIToken.deploy(tokenName, tokenSymbol, initialSupply, treasuryAddress, initialOwner);

  await wagmiToken.deployed();
  console.log("WAGMIToken deployed to:", wagmiToken.address);

  // Guardar la dirección del token en el archivo .env
  const envPath = "./.env";
  fs.appendFileSync(envPath, `STAKING_TOKEN_ADDRESS=${wagmiToken.address}\n`);
  console.log(`STAKING_TOKEN_ADDRESS saved to ${envPath}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });