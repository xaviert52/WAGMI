// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ITreasury {
    function allocateFunds(bytes32 category, uint256 amount) external;
    function transferFunds(bytes32 category, address payable recipient, uint256 amount) external;
    function getBalance() external view returns (uint256);
}