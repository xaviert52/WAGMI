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
    uint256 public maxStakePerUser;
    uint256 public maxStakePerWhale; // Restriction for whales

    event Staked(address indexed user, uint256 amount, uint256 planIndex);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event EarlyWithdrawal(address indexed user, uint256 amount, uint256 penalty);
    event RewardPoolAdded(uint256 amount);

    /// @notice Constructor to initialize the staking contract.
    /// @param _stakingToken Address of the staking token.
    /// @param _initialOwner Address of the initial owner.
    /// @param _maxStakePerUser Maximum stake allowed per user.
    /// @param _maxStakePerWhale Maximum stake allowed for whales.
    /// @param _lockPeriods Array of lock periods for staking plans.
    /// @param _rewardRates Array of reward rates for staking plans.
    /// @param _earlyWithdrawalPenalties Array of penalties for early withdrawals.
    constructor(
        address _stakingToken,
        address _initialOwner,
        uint256 _maxStakePerUser,
        uint256 _maxStakePerWhale,
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
        maxStakePerUser = _maxStakePerUser;
        maxStakePerWhale = _maxStakePerWhale;

        for (uint256 i = 0; i < _lockPeriods.length; i++) {
            stakingPlans.push(Plan({
                lockPeriod: _lockPeriods[i],
                rewardRate: _rewardRates[i],
                earlyWithdrawalPenalty: _earlyWithdrawalPenalties[i]
            }));
        }
    }

    /// @notice Adds funds to the reward pool.
    /// @param amount Amount to add to the reward pool.
    function addRewardPool(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        rewardPool += amount;
        emit RewardPoolAdded(amount);
    }

    /// @notice Allows users to stake tokens.
    /// @param _amount Amount of tokens to stake.
    /// @param _planIndex Index of the staking plan.
    function stake(uint256 _amount, uint256 _planIndex) external nonReentrant whenNotPaused {
        require(_amount > 0, "Cannot stake zero tokens");
        require(_planIndex < stakingPlans.length, "Invalid staking plan");

        uint256 userTotalStake = getUserTotalStake(msg.sender);
        require(userTotalStake + _amount <= maxStakePerUser, "Stake exceeds maximum allowed per user");
        require(totalStaked + _amount <= maxStakePerWhale, "Stake exceeds maximum allowed for whales");

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
    /// @param _stakeIndex Index of the stake to withdraw.
    function withdraw(uint256 _stakeIndex) external nonReentrant whenNotPaused {
        require(_stakeIndex < stakes[msg.sender].length, "Invalid stake index");

        Stake memory userStake = stakes[msg.sender][_stakeIndex];
        uint256 stakingDuration = block.timestamp - userStake.startTime;
        Plan memory plan = getPlanByLockPeriod(userStake.lockPeriod);

        uint256 reward = calculateReward(userStake, stakingDuration);
        uint256 amountToTransfer = userStake.amount + reward;
        uint256 penalty = 0;

        if (userStake.lockPeriod > 0 && stakingDuration < userStake.lockPeriod) {
            penalty = (userStake.amount * plan.earlyWithdrawalPenalty) / 100;
            amountToTransfer -= penalty;
            rewardPool += penalty;
            emit EarlyWithdrawal(msg.sender, userStake.amount, penalty);
        }

        require(amountToTransfer <= stakingToken.balanceOf(address(this)), "Insufficient contract balance");

        stakes[msg.sender][_stakeIndex] = stakes[msg.sender][stakes[msg.sender].length - 1];
        stakes[msg.sender].pop();

        totalStaked -= userStake.amount;
        require(stakingToken.transfer(msg.sender, amountToTransfer), "Transfer failed");
        emit Withdrawn(msg.sender, userStake.amount, reward);
    }

    /// @notice Calculates the reward for a given stake.
    /// @param _stake Stake details.
    /// @param _duration Duration of the stake.
    /// @return Reward amount.
    function calculateReward(Stake memory _stake, uint256 _duration) internal pure returns (uint256) {
        return (_stake.amount * _stake.rewardRate * _duration) / (365 days * 100);
    }

    /// @notice Gets the total stake of a user.
    /// @param _user Address of the user.
    /// @return Total stake amount.
    function getUserTotalStake(address _user) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < stakes[_user].length; i++) {
            total += stakes[_user][i].amount;
        }
        return total;
    }

    /// @notice Gets the voting power of a user.
    /// @param _user Address of the user.
    /// @return Voting power.
    function getVotingPower(address _user) external view returns (uint256) {
        uint256 totalVotingPower = 0;
        for (uint256 i = 0; i < stakes[_user].length; i++) {
            Stake memory userStake = stakes[_user][i];
            uint256 multiplier = 1e18;
            if (userStake.lockPeriod == 30 days) multiplier = 11e17;
            else if (userStake.lockPeriod == 90 days) multiplier = 13e17;
            else if (userStake.lockPeriod == 180 days) multiplier = 16e17;
            else if (userStake.lockPeriod == 365 days) multiplier = 2e18;

            totalVotingPower += (userStake.amount * multiplier) / 1e18;
        }
        return totalVotingPower;
    }

    /// @notice Gets the staking plan by lock period.
    /// @param lockPeriod Lock period of the plan.
    /// @return Staking plan details.
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