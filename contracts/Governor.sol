// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "./Staking.sol";

contract WAGMIGovernor is Governor, GovernorTimelockControl {
    StakingContract public stakingContract;

    constructor(StakingContract _stakingContract, TimelockController _timelock)
        Governor("WAGMIGovernor")
        GovernorTimelockControl(_timelock)
    {
        require(address(_stakingContract) != address(0), "Invalid staking contract address");
        require(address(_timelock) != address(0), "Invalid timelock address");

        stakingContract = _stakingContract;
    }

    // Voting delay (in blocks)
    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    // Voting period (in blocks)
    function votingPeriod() public pure override returns (uint256) {
        return 45818; // ~1 week in blocks
    }

    // Quorum required for a proposal to pass
    function quorum(uint256 blockNumber) public view override returns (uint256) {
        return 1000e18; // 1000 tokens staked required for quorum
    }

    // Minimum voting power required to create a proposal
    function proposalThreshold() public view override returns (uint256) {
        return 100e18; // 100 tokens staked required to create a proposal
    }

    // Get voting power from the staking contract
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /* params */
    ) internal view override returns (uint256) {
        return stakingContract.getVotingPower(account);
    }

    // Required by Solidity for compatibility with GovernorTimelockControl
    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function supportsInterface(bytes4 interfaceId) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}