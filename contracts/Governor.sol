// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "./Staking.sol";

/// @title WAGMIGovernor
/// @notice Governance contract for the WAGMI DAO.
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

    /// @notice Voting delay (in blocks).
    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    /// @notice Voting period (in blocks).
    function votingPeriod() public pure override returns (uint256) {
        return 45818; // ~1 week in blocks
    }

    /// @notice Quorum required for a proposal to pass.
    function quorum(uint256 blockNumber) public view override returns (uint256) {
        return 1000e18; // 1000 tokens staked required for quorum
    }

    /// @notice Minimum voting power required to create a proposal.
    function proposalThreshold() public view override returns (uint256) {
        return 100e18; // 100 tokens staked required to create a proposal
    }

    /// @notice Gets voting power from the staking contract.
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /* params */
    ) internal view override returns (uint256) {
        return stakingContract.getVotingPower(account);
    }

    /// @notice Checks if quorum is reached for a proposal.
    function _quorumReached(uint256 proposalId) internal view override returns (bool) {
        return quorum(proposalSnapshot(proposalId)) <= proposalVotes(proposalId).forVotes;
    }

    /// @notice Checks if a proposal has succeeded.
    function _voteSucceeded(uint256 proposalId) internal view override returns (bool) {
        return proposalVotes(proposalId).forVotes > proposalVotes(proposalId).againstVotes;
    }

    /// @notice Counts votes for a proposal.
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory params
    ) internal override {
        super._countVote(proposalId, account, support, weight, params);
    }

    /// @notice Required by Solidity for compatibility with GovernorTimelockControl.
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