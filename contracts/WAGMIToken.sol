// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StakingContract is Ownable, ReentrancyGuard {
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
    }

    mapping(address => Stake[]) public stakes;
    Plan[] public stakingPlans;

    uint256 public totalStaked;
    uint256 public rewardPool;
    uint256 public earlyWithdrawalPenalty;
    uint256 public maxStakePerUser;

    event Staked(address indexed user, uint256 amount, uint256 planIndex);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event EarlyWithdrawal(address indexed user, uint256 amount, uint256 penalty);
    event RewardPoolAdded(uint256 amount);

    constructor(
        address _stakingToken,
        uint256 _maxStakePerUser,
        uint256 _earlyWithdrawalPenalty,
        uint256[] memory _lockPeriods,
        uint256[] memory _rewardRates
    ) {
        require(_stakingToken != address(0), "Invalid token address");
        stakingToken = IERC20(_stakingToken);
        maxStakePerUser = _maxStakePerUser;
        earlyWithdrawalPenalty = _earlyWithdrawalPenalty;

        for (uint256 i = 0; i < _lockPeriods.length; i++) {
            stakingPlans.push(Plan({lockPeriod: _lockPeriods[i], rewardRate: _rewardRates[i]}));
        }
    }

    function addRewardPool(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        rewardPool += amount;
        emit RewardPoolAdded(amount);
    }

    function stake(uint256 _amount, uint256 _planIndex) external nonReentrant {
        require(_amount > 0, "Cannot stake zero tokens");
        require(_planIndex < stakingPlans.length, "Invalid staking plan");

        uint256 userTotalStake = getUserTotalStake(msg.sender);
        require(userTotalStake + _amount <= maxStakePerUser, "Stake exceeds maximum allowed per user");

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

    function withdraw(uint256 _stakeIndex) external nonReentrant {
        require(_stakeIndex < stakes[msg.sender].length, "Invalid stake index");

        Stake memory userStake = stakes[msg.sender][_stakeIndex];
        uint256 stakingDuration = block.timestamp - userStake.startTime;
        uint256 reward = calculateReward(userStake, stakingDuration);

        uint256 amountToTransfer = userStake.amount + reward;
        uint256 penalty = 0;

        if (userStake.lockPeriod > 0 && stakingDuration < userStake.lockPeriod) {
            penalty = (userStake.amount * earlyWithdrawalPenalty) / 100;
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

    function calculateReward(Stake memory _stake, uint256 _duration) internal pure returns (uint256) {
        return (_stake.amount * _stake.rewardRate * _duration) / (365 days * 100);
    }

    function getUserTotalStake(address _user) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < stakes[_user].length; i++) {
            total += stakes[_user][i].amount;
        }
        return total;
    }

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
}

//1 vulnerability = hardcoded-credentials Embedding credentials in source code risks unauthorized access