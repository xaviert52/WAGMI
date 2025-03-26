// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title WAGMIToken
/// @notice ERC-20 token for the WAGMI DAO with burn and reward pool fees.
contract WAGMIToken is ERC20, Ownable, ReentrancyGuard, Pausable {
    uint256 public burnFee; // Fee percentage for burning tokens
    uint256 public rewardPoolFee; // Fee percentage for transferring to the reward pool
    uint256 public totalFee; // Total fee percentage (burnFee + rewardPoolFee)
    address public rewardPool; // Address of the reward pool contract

    mapping(address => bool) public feeExempt; // Addresses exempt from fees

    event FeeStructureUpdated(uint256 burnFee, uint256 rewardPoolFee);
    event FeeExemptionUpdated(address indexed account, bool isExempt);
    event RewardPoolAddressUpdated(address indexed newRewardPoolAddress);

    /// @notice Constructor to initialize the WAGMIToken contract.
    /// @param _name Name of the token.
    /// @param _symbol Symbol of the token.
    /// @param _initialSupply Initial supply of the token.
    /// @param _initialOwner Address of the initial owner.
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _initialOwner
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply * 10 ** decimals());
        transferOwnership(_initialOwner);

        // Default fees: 1% burn, 1% reward pool
        burnFee = 1;
        rewardPoolFee = 1;
        totalFee = burnFee + rewardPoolFee;
    }

    /// @notice Updates the fee structure.
    /// @param _burnFee New burn fee percentage.
    /// @param _rewardPoolFee New reward pool fee percentage.
    function setFeeStructure(uint256 _burnFee, uint256 _rewardPoolFee) external onlyOwner {
        require(_burnFee + _rewardPoolFee <= 100, "Total fee cannot exceed 100%");
        burnFee = _burnFee;
        rewardPoolFee = _rewardPoolFee;
        totalFee = burnFee + rewardPoolFee;

        emit FeeStructureUpdated(burnFee, rewardPoolFee);
    }

    /// @notice Updates the reward pool address.
    /// @param _rewardPool New reward pool address.
    function setRewardPool(address _rewardPool) external onlyOwner {
        require(_rewardPool != address(0), "Invalid reward pool address");
        rewardPool = _rewardPool;

        emit RewardPoolAddressUpdated(rewardPool);
    }

    /// @notice Sets fee exemption for an address.
    /// @param account Address to exempt from fees.
    /// @param isExempt Whether the address is exempt from fees.
    function setFeeExemption(address account, bool isExempt) external onlyOwner {
        feeExempt[account] = isExempt;

        emit FeeExemptionUpdated(account, isExempt);
    }

    /// @notice Pauses all token transfers.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses all token transfers.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Overrides the ERC20 transfer function to include fees.
    /// @param sender Address sending the tokens.
    /// @param recipient Address receiving the tokens.
    /// @param amount Amount of tokens to transfer.
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override whenNotPaused nonReentrant {
        require(amount > 0, "Transfer amount must be greater than zero");

        // Check if the sender or recipient is exempt from fees
        if (feeExempt[sender] || feeExempt[recipient] || totalFee == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 burnAmount = (amount * burnFee) / 100;
            uint256 rewardPoolAmount = (amount * rewardPoolFee) / 100;
            uint256 netAmount = amount - burnAmount - rewardPoolAmount;

            // Ensure no rounding issues cause negative netAmount
            require(netAmount >= 0, "Net amount must be non-negative");

            // Burn the burnAmount
            if (burnAmount > 0) {
                _burn(sender, burnAmount);
            }

            // Transfer the rewardPoolAmount to the reward pool
            if (rewardPoolAmount > 0) {
                require(rewardPool != address(0), "Reward pool address not set");
                super._transfer(sender, rewardPool, rewardPoolAmount);
            }

            // Transfer the remaining amount to the recipient
            super._transfer(sender, recipient, netAmount);
        }
    }
}