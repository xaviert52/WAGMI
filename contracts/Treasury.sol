// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Treasury
/// @notice Manages the initial distribution of funds to multisig wallets controlled by the DAO.
contract Treasury is Ownable, ReentrancyGuard {
    event FundsTransferred(address indexed recipient, uint256 amount);

    /// @notice Transfers funds to a specified recipient.
    /// @param recipient The address of the recipient (e.g., a multisig wallet).
    /// @param amount The amount of funds to transfer.
    function transferFunds(address payable recipient, uint256 amount) external onlyOwner nonReentrant {
        require(recipient != address(0), "Invalid recipient address");
        require(address(this).balance >= amount, "Insufficient balance");

        recipient.transfer(amount);
        emit FundsTransferred(recipient, amount);
    }

    /// @notice Allows the contract to receive Ether.
    receive() external payable {}

    /// @notice Returns the current balance of the contract.
    /// @return The balance of the contract in wei.
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}