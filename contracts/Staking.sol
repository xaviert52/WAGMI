// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title StakingContract
/// @notice Allows users to stake tokens and earn rewards based on lock periods.
contract StakingContract is Ownable, ReentrancyGuard, Pausable {
    IERC20 public stakingToken;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lockPeriod;
        uint256 rewardRate;
    }

    struct Plan {
        uint256 lockPeriod;
        uint256 rewardRate;
        uint256 earlyWithdrawalPenalty; // Penalty for early withdrawal (percentage)
    }

    mapping(address => Stake[]) public stakes;
    Plan[] public stakingPlans;

    uint256 public totalStaked;
    uint256 public rewardPool;
    uint256 public maxStake;

    event Staked(address indexed user, uint256 amount, uint256 planIndex);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event EarlyWithdrawal(address indexed user, uint256 amount, uint256 penalty);
    event RewardPoolAdded(uint256 amount);
    event LockedFundsAccessed(uint256 amount);

    /// @notice Constructor to initialize the staking contract.
    constructor(
        address _stakingToken,
        address _initialOwner,
        uint256 _maxStake,
        uint256[] memory _lockPeriods,
        uint256[] memory _rewardRates,
        uint256[] memory _earlyWithdrawalPenalties
    ) Ownable(_initialOwner) {
        require(_stakingToken != address(0), "Invalid token address");
        require(
            _lockPeriods.length == _rewardRates.length &&
            _rewardRates.length == _earlyWithdrawalPenalties.length,
            "Mismatched plan parameters"
        );

        stakingToken = IERC20(_stakingToken);
        maxStake = _maxStake;

        for (uint256 i = 0; i < _lockPeriods.length; i++) {
            stakingPlans.push(Plan({
                lockPeriod: _lockPeriods[i],
                rewardRate: _rewardRates[i],
                earlyWithdrawalPenalty: _earlyWithdrawalPenalties[i]
            }));
        }
    }

    /// @notice Adds funds to the reward pool.
    function addRewardPool(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        rewardPool += amount;
        emit RewardPoolAdded(amount);
    }

    /// @notice Allows users to stake tokens.
    function stake(uint256 _amount, uint256 _planIndex) external nonReentrant whenNotPaused {
        require(_amount > 0, "Cannot stake zero tokens");
        require(_planIndex < stakingPlans.length, "Invalid staking plan");

        uint256 userTotalStake = getUserTotalStake(msg.sender);
        require(userTotalStake + _amount <= maxStake, "Stake exceeds maximum allowed");

        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        Plan memory plan = stakingPlans[_planIndex];
        stakes[msg.sender].push(Stake({
            amount: _amount,
            startTime: block.timestamp,
            lockPeriod: plan.lockPeriod,
            rewardRate: plan.rewardRate
        }));

        totalStaked += _amount;
        emit Staked(msg.sender, _amount, _planIndex);
    }

    /// @notice Allows users to withdraw their staked tokens and rewards.
    function withdraw(uint256 _stakeIndex) external nonReentrant whenNotPaused {
        require(_stakeIndex < stakes[msg.sender].length, "Invalid stake index");

        Stake memory userStake = stakes[msg.sender][_stakeIndex];
        uint256 stakingDuration = block.timestamp - userStake.startTime;
        Plan memory plan = getPlanByLockPeriod(userStake.lockPeriod);

        uint256 reward = calculateReward(userStake, stakingDuration);
        uint256 amountToTransfer = userStake.amount + reward;
        uint256 penalty = 0;

        if (userStake.lockPeriod > 0 && stakingDuration < userStake.lockPeriod) {
            uint256 elapsedPercentage = (stakingDuration * 100) / userStake.lockPeriod;

            if (elapsedPercentage <= 25) {
                penalty = (userStake.amount * plan.earlyWithdrawalPenalty) / 100;
            } else if (elapsedPercentage <= 50) {
                penalty = (userStake.amount * plan.earlyWithdrawalPenalty) / 200; // Half of the initial penalty
            } else if (elapsedPercentage <= 75) {
                penalty = (userStake.amount * plan.earlyWithdrawalPenalty) / 400; // Quarter of the initial penalty
            } else {
                penalty = (userStake.amount * plan.earlyWithdrawalPenalty) / 800; // Eighth of the initial penalty
            }

            amountToTransfer -= penalty;
            rewardPool += penalty;
            emit EarlyWithdrawal(msg.sender, userStake.amount, penalty);
        }

        require(amountToTransfer <= stakingToken.balanceOf(address(this)), "Insufficient contract balance");
        require(reward <= rewardPool, "Insufficient reward pool");

        stakes[msg.sender][_stakeIndex] = stakes[msg.sender][stakes[msg.sender].length - 1];
        stakes[msg.sender].pop();

        totalStaked -= userStake.amount;
        rewardPool -= reward;
        require(stakingToken.transfer(msg.sender, amountToTransfer), "Transfer failed");
        emit Withdrawn(msg.sender, userStake.amount, reward);
    }

    /// @notice Allows the DAO to access up to 30% of the locked funds.
    function accessLockedFunds(uint256 amount) external onlyOwner {
        uint256 maxAllowed = (totalStaked * 30) / 100;
        require(amount <= maxAllowed, "Exceeds 30% of locked funds");
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
        emit LockedFundsAccessed(amount);
    }

    /// @notice Calculates the reward for a given stake.
    function calculateReward(Stake memory _stake, uint256 _duration) internal pure returns (uint256) {
        return (_stake.amount * _stake.rewardRate * _duration) / (365 days * 100);
    }

    /// @notice Gets the total stake of a user.
    function getUserTotalStake(address _user) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < stakes[_user].length; i++) {
            total += stakes[_user][i].amount;
        }
        return total;
    }

    /// @notice Gets the staking plan by lock period.
    function getPlanByLockPeriod(uint256 lockPeriod) internal view returns (Plan memory) {
        for (uint256 i = 0; i < stakingPlans.length; i++) {
            if (stakingPlans[i].lockPeriod == lockPeriod) {
                return stakingPlans[i];
            }
        }
        revert("Plan not found");
    }

    /// @notice Pauses the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
    }
}