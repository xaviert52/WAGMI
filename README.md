# WAGMI DAO Ecosystem

## Overview
The **WAGMI DAO Ecosystem** is a decentralized platform that combines governance, staking, and treasury management to empower the community. The project is built on the principles of decentralization, transparency, and sustainability.

### Key Features
1. **Governance**: 
   - Community-driven decision-making through proposals and voting.
   - Powered by the $WAGMI token and staking.

2. **Staking**:
   - Stake $WAGMI tokens to earn rewards and gain voting power.
   - Flexible and locked staking options with varying rewards.

3. **Treasury**:
   - Manages funds collected from transaction fees and staking penalties.
   - Funds are allocated to ecosystem growth, partnerships, and community rewards.

---

## Workspace Structure
### The project is organized as follows:
1. vscode/ 
     - settings.json # VSCode-specific settings 
2. WAGMI/ 
     - .env # Environment variables (excluded from Git) 
     - .gitignore # Files and folders to ignore in Git 
      -hardhat.config.js # Hardhat configuration for Solidity development 
     - package.json # Node.js dependencies and scripts 
     - README.md # Project documentation 
     - cache/ # Hardhat cache (excluded from Git) 
     - contracts/ # Solidity smart contracts 
          + Governor.sol # Governance contract 
          + Staking.sol # Staking contract 
          + Timelock.sol # Timelock controller for proposal execution 
          + Treasury.sol # Treasury management contract 
          + WAGMIToken.sol # ERC-20 token contract for $WAGMI 
          + interfaces/ # Interfaces for contracts 
               - iGovernor.sol # Interface for the Governor contract 
               - IStaking.sol # Interface for the Staking contract 
               - ITreasury.sol # Interface for the Treasury contract 
     - frontend/ # Frontend code (React-based) 
          + src/ 
               - App.js # Main React component 
               - index.js # Entry point for the React app 
     - scripts/ # Deployment scripts 
          + deployGovernor.js # Deploys the Governor contract 
          + deployStaking.js # Deploys the Staking contract 
          + deployTimelock.js # Deploys the Timelock contract 
          + deployTreasury.js # Deploys the Treasury contract 
          + deployWAGMIToken.js # Deploys the WAGMI token contract 
     - test/ # Unit tests for smart contracts 
          + Governor.test.js # Tests for the Governor contract 
          + Staking.test.js # Tests for the Staking contract 
          + Timelock.test.js # Tests for the Timelock contract 
          + Treasury.test.js # Tests for the Treasury contract 
          + WAGMIToken.test.js # Tests for the WAGMI token contract


---

## Installation and Setup

### Prerequisites
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Hardhat](https://hardhat.org/)
- [MetaMask](https://metamask.io/) (for interacting with the deployed contracts)

### Steps
1. **Clone the repository**:
   ```bash
   git clone https://github.com/xaviert52/WAGMI.git
   cd WAGMI-DAO

2. **install dependencies**:
   - npm install

3. **Create a .env file in the WAGMI/ directory with the following variables**:
     - PRIVATE_KEY=your_private_key
     - MOONSCAN_API_KEY=your_moonscan_api_key
     - INITIAL_OWNER=your_wallet_address
     - TREASURY_ADDRESS=treasury_contract_address
     - STAKING_TOKEN_ADDRESS=wagmi_token_address
     - TIMELOCK_MIN_DELAY=3600

4. **Compile the contracts**:
   - npx hardhat compile

5. **Run tests**:
   - npx hardhat test


### Deployment
Deploy to Moonbase Alpha (Testnet)
1. **Deploy the contracts**:
     - npx hardhat run scripts/deployWAGMIToken.js --network moonbase
     - npx hardhat run scripts/deployTreasury.js --network moonbase
     - npx hardhat run scripts/deployStaking.js --network moonbase
     - npx hardhat run scripts/deployTimelock.js --network moonbase
     - npx hardhat run scripts/deployGovernor.js --network moonbase

2. **Verify the contracts on Moonbeam Explorer**:
     - npx hardhat verify --network moonbase <contract_address> <constructor_arguments>

### Usage
1. **Staking**
     - Stake $WAGMI tokens to earn rewards and gain voting power.
     - Use the frontend to interact with the staking contract.
2. **Governance**
     - Propose and vote on decisions using the $WAGMI token.
     - Only stakers can participate in governance.
3. **Treasury**
     - Funds are managed transparently and allocated based on community decisions.
4. **Contributing**
     - We welcome contributions! Please fork the repository and submit a pull request.

### License
This project is licensed under the MIT License. See the LICENSE file for details.