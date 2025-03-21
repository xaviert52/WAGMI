// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IStaking {
    function stake(uint256 _amount, uint256 _planIndex) external;
    function withdraw(uint256 _stakeIndex) external;
    function getVotingPower(address _user) external view returns (uint256);
}