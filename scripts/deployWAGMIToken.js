const { ethers } = require("hardhat");

async function main() {
  // Valores que se pasarán al constructor
  const tokenName = "We All Gonna Make It"; // Nombre del token
  const tokenSymbol = "WAGMI"; // Símbolo del token
  const initialSupply = ethers.utils.parseEther("10000000"); // 10 millones de tokens
  const treasuryAddress = "0xEAC8800C2758F4683bBaB6197acE7A26802856D9"; // Dirección del contrato de tesorería
  const initialOwner = "0x1c81F206E72F3659FaE9Fdc6c22Bd355fbD68BF1";

  if (!treasuryAddress || !initialOwner) {
    throw new Error("Please set TREASURY_ADDRESS and INITIAL_OWNER in your .env file");
  }

  console.log("Deploying WAGMIToken...");
  console.log("Token Name:", tokenName);
  console.log("Token Symbol:", tokenSymbol);
  console.log("Initial Supply:", initialSupply.toString());
  console.log("Treasury Address:", treasuryAddress);

  // Obtener la fábrica del contrato
  const WAGMIToken = await ethers.getContractFactory("WAGMIToken");

  // Desplegar el contrato
  const wagmiToken = await WAGMIToken.deploy(tokenName, tokenSymbol, initialSupply, treasuryAddress, initialOwner);

  await wagmiToken.deployed();
  console.log("WAGMIToken deployed to:", wagmiToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });