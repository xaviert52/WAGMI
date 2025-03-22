// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title WAGMIToken
/// @notice ERC-20 token for the WAGMI DAO with burn and treasury fees.
contract WAGMIToken is ERC20, Ownable, ReentrancyGuard, Pausable {
    uint256 public burnFee; // Fee percentage for burning tokens
    uint256 public treasuryFee; // Fee percentage for transferring to the treasury
    uint256 public totalFee; // Total fee percentage (burnFee + treasuryFee)
    address public treasuryAddress; // Address of the treasury contract

    mapping(address => bool) public feeExempt; // Addresses exempt from fees

    event FeeStructureUpdated(uint256 burnFee, uint256 treasuryFee);
    event FeeExemptionUpdated(address indexed account, bool isExempt);
    event TreasuryAddressUpdated(address indexed newTreasuryAddress);

    /// @notice Constructor to initialize the WAGMIToken contract.
    /// @param _name Name of the token.
    /// @param _symbol Symbol of the token.
    /// @param _initialSupply Initial supply of the token.
    /// @param _treasuryAddress Address of the treasury contract.
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _treasuryAddress
    ) ERC20(_name, _symbol) {
        require(_treasuryAddress != address(0), "Invalid treasury address");

        _mint(msg.sender, _initialSupply);
        treasuryAddress = _treasuryAddress;

        // Default fees: 1% burn, 1% treasury
        burnFee = 1;
        treasuryFee = 1;
        totalFee = burnFee + treasuryFee;
    }

    /// @notice Updates the fee structure.
    /// @param _burnFee New burn fee percentage.
    /// @param _treasuryFee New treasury fee percentage.
    function setFeeStructure(uint256 _burnFee, uint256 _treasuryFee) external onlyOwner {
        require(_burnFee + _treasuryFee <= 100, "Total fee cannot exceed 100%");
        burnFee = _burnFee;
        treasuryFee = _treasuryFee;
        totalFee = burnFee + treasuryFee;

        emit FeeStructureUpdated(burnFee, treasuryFee);
    }

    /// @notice Updates the treasury address.
    /// @param _treasuryAddress New treasury address.
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0), "Invalid treasury address");
        treasuryAddress = _treasuryAddress;

        emit TreasuryAddressUpdated(treasuryAddress);
    }

    /// @notice Sets fee exemption for an address.
    /// @param account Address to exempt from fees.
    /// @param isExempt Whether the address is exempt from fees.
    function setFeeExemption(address account, bool isExempt) external onlyOwner {
        feeExempt[account] = isExempt;

        emit FeeExemptionUpdated(account, isExempt);
    }

    /// @notice Pauses token transfers.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses token transfers.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Overrides the ERC20 transfer function to include fees.
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override whenNotPaused {
        require(amount > 0, "Transfer amount must be greater than zero");

        if (feeExempt[sender] || feeExempt[recipient] || totalFee == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 burnAmount = (amount * burnFee) / 100;
            uint256 treasuryAmount = (amount * treasuryFee) / 100;
            uint256 netAmount = amount - burnAmount - treasuryAmount;

            // Ensure no rounding issues cause negative netAmount
            require(netAmount >= 0, "Net amount must be non-negative");

            // Burn the burnAmount
            if (burnAmount > 0) {
                _burn(sender, burnAmount);
            }

            // Transfer the treasuryAmount to the treasury
            if (treasuryAmount > 0) {
                super._transfer(sender, treasuryAddress, treasuryAmount);
            }

            // Transfer the remaining amount to the recipient
            super._transfer(sender, recipient, netAmount);
        }
    }
}