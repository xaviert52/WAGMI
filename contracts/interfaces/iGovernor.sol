// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IGovernor {
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function quorum(uint256 blockNumber) external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
}