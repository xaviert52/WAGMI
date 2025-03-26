const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Step 1: Deploy WAGMIToken
  console.log("Deploying WAGMIToken...");
  const WAGMIToken = await ethers.getContractFactory("WAGMIToken");
  const wagmiToken = await WAGMIToken.deploy(
    "WAGMI Token",
    "WAGMI",
    ethers.utils.parseEther("10000000"), // 10,000,000 tokens
    1, // 1% burn fee
    1, // 1% reward pool fee
    ethers.constants.AddressZero // Placeholder for reward pool (to be set later)
  );
  await wagmiToken.deployed();
  console.log("WAGMIToken deployed to:", wagmiToken.address);

  // Step 2: Deploy StakingContract
  console.log("Deploying StakingContract...");
  const Staking = await ethers.getContractFactory("StakingContract");
  const staking = await Staking.deploy(
    wagmiToken.address, // Address of the WAGMIToken
    deployer.address, // Initial owner
    ethers.utils.parseEther("10000"), // Max stake
    [30 * 24 * 60 * 60, 90 * 24 * 60 * 60, 180 * 24 * 60 * 60, 365 * 24 * 60 * 60], // Lock periods
    [5, 10, 15, 20], // Reward rates
    [20, 15, 10, 5] // Early withdrawal penalties
  );
  await staking.deployed();
  console.log("StakingContract deployed to:", staking.address);

  // Step 3: Set reward pool in WAGMIToken
  console.log("Setting reward pool in WAGMIToken...");
  await wagmiToken.setRewardPool(staking.address);
  console.log("Reward pool set to:", staking.address);

  console.log("Deployment completed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });