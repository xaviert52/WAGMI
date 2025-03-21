require("dotenv").config();
const { ethers, upgrades } = require("hardhat");

async function main() {
  // Load environment variables
  const initialOwner = process.env.INITIAL_OWNER; // Address of the initial owner
  const treasuryAddress = process.env.TREASURY_ADDRESS; // Address of the Treasury contract

  // Validate environment variables
  if (!initialOwner || !treasuryAddress) {
    throw new Error("Please set INITIAL_OWNER and TREASURY_ADDRESS in your .env file");
  }

  console.log("Deploying WAGMIToken...");
  console.log("Initial Owner:", initialOwner);
  console.log("Treasury Address:", treasuryAddress);

  // Get the contract factory
  const WAGMIToken = await ethers.getContractFactory("WAGMI");

  // Deploy the proxy contract
  const wagmiToken = await upgrades.deployProxy(WAGMIToken, [initialOwner, treasuryAddress], {
    initializer: "initialize", // Specify the initializer function
  });

  // Wait for the deployment to complete
  await wagmiToken.deployed();

  console.log("WAGMIToken deployed to:", wagmiToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });