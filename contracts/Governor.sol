// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "./Staking.sol"; // Importamos el contrato de staking

contract WAGMIGovernor is Governor, GovernorTimelockControl {
    StakingContract public stakingContract; // Referencia al contrato de staking

    constructor(StakingContract _stakingContract, TimelockController _timelock)
        Governor("WAGMIGovernor")
        GovernorTimelockControl(_timelock)
    {
        stakingContract = _stakingContract;
    }

    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 bloque
    }

    function votingPeriod() public pure override returns (uint256) {
        return 45818; // ~1 semana en bloques
    }

    function quorum(uint256 blockNumber) public view override returns (uint256) {
        return 1000e18; // 1000 tokens staked requeridos para el quórum
    }

    function proposalThreshold() public view override returns (uint256) {
        return 100e18; // 100 tokens staked requeridos para crear una propuesta
    }

    // Función personalizada para obtener el poder de voto desde el contrato de staking
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /* params */
    ) internal view override returns (uint256) {
        return stakingContract.getVotingPower(account); // Consultamos el poder de voto desde el contrato de staking
    }
}