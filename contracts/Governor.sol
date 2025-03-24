// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "./Staking.sol";

/// @title WAGMIGovernor
/// @notice Governance contract for the WAGMI DAO.
contract WAGMIGovernor is Governor, GovernorTimelockControl {
    StakingContract public stakingContract;

    /// @notice Constructor to initialize the WAGMIGovernor contract.
    /// @param _stakingContract Address of the staking contract.
    /// @param _timelock Address of the timelock contract.
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
    /// @param blockNumber Block number for which the quorum is calculated.
    /// @return Quorum in voting power.
    function quorum(uint256 blockNumber) public view override returns (uint256) {
        return 1000e18; // 1000 tokens staked required for quorum
    }

    /// @notice Minimum voting power required to create a proposal.
    /// @return Proposal threshold in voting power.
    function proposalThreshold() public view override returns (uint256) {
        return 100e18; // 100 tokens staked required to create a proposal
    }

    /// @notice Gets voting power from the staking contract.
    /// @param account Address of the voter.
    /// @param blockNumber Block number for which the voting power is calculated.
    /// @param params Additional parameters (not used).
    /// @return Voting power of the account.
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) internal view override returns (uint256) {
        return stakingContract.getVotingPower(account);
    }

    /// @notice Required by Solidity for compatibility with GovernorTimelockControl.
    /// @param proposalId ID of the proposal.
    /// @return State of the proposal.
    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    /// @notice Creates a new proposal.
    /// @param targets List of target addresses for calls to be made.
    /// @param values List of values (in wei) to be passed to the calls.
    /// @param calldatas List of calldata to be passed to the calls.
    /// @param description Description of the proposal.
    /// @return Proposal ID.
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    /// @notice Executes a proposal.
    /// @param proposalId ID of the proposal.
    /// @param targets List of target addresses for calls to be made.
    /// @param values List of values (in wei) to be passed to the calls.
    /// @param calldatas List of calldata to be passed to the calls.
    /// @param descriptionHash Hash of the proposal description.
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        GovernorTimelockControl._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    /// @notice Cancels a proposal.
    /// @param targets List of target addresses for calls to be made.
    /// @param values List of values (in wei) to be passed to the calls.
    /// @param calldatas List of calldata to be passed to the calls.
    /// @param descriptionHash Hash of the proposal description.
    /// @return Proposal ID.
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return GovernorTimelockControl._cancel(targets, values, calldatas, descriptionHash);
    }

    /// @notice Checks if the contract supports a given interface.
    /// @param interfaceId ID of the interface.
    /// @return True if the interface is supported, false otherwise.
    function supportsInterface(bytes4 interfaceId) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Implements the `_executor` function required by GovernorTimelockControl.
    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return GovernorTimelockControl._executor();
    }
}