// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title Treasury
/// @notice Manages funds for the WAGMI DAO.
contract Treasury is Ownable, ReentrancyGuard, Pausable {
    mapping(bytes32 => uint256) public funds;
    mapping(bytes32 => bool) public allowedCategories;

    event FundsReceived(address indexed sender, uint256 amount);
    event FundsAllocated(bytes32 indexed category, uint256 amount);
    event FundsTransferred(bytes32 indexed category, address indexed recipient, uint256 amount);
    event CategoryAdded(bytes32 indexed category);
    event CategoryRemoved(bytes32 indexed category);

    /// @notice Constructor to initialize the treasury contract.
    /// @param _initialOwner Address of the initial owner.
    constructor(address _initialOwner) Ownable(_initialOwner) {}

    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    function addCategory(bytes32 category) external onlyOwner {
        require(category != bytes32(0), "Category cannot be empty");
        require(!allowedCategories[category], "Category already exists");
        allowedCategories[category] = true;
        emit CategoryAdded(category);
    }

    function removeCategory(bytes32 category) external onlyOwner {
        require(allowedCategories[category], "Category does not exist");
        delete allowedCategories[category];
        emit CategoryRemoved(category);
    }

    function allocateFunds(bytes32 category, uint256 amount) external onlyOwner whenNotPaused {
        require(allowedCategories[category], "Invalid category");
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient balance");

        funds[category] += amount;
        emit FundsAllocated(category, amount);
    }

    function transferFunds(bytes32 category, address payable recipient, uint256 amount)
        external
        onlyOwner
        nonReentrant
        whenNotPaused
    {
        require(allowedCategories[category], "Invalid category");
        require(funds[category] >= amount, "Insufficient funds in category");
        require(recipient != address(0), "Cannot transfer to zero address");
        require(amount > 0, "Amount must be greater than zero");

        funds[category] -= amount;
        recipient.transfer(amount);
        emit FundsTransferred(category, recipient, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}