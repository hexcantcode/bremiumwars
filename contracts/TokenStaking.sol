// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenStaking is Ownable {
    using SafeERC20 for IERC20;

    struct Stake {
        uint256 amount;
        uint256 epochId;
    }

    // State variables
    IERC20 public honeyToken;
    address public bettingSystem;
    mapping(address => Stake[]) public stakes;
    mapping(uint256 => uint256) public totalStakedPerEpoch;
    uint256 public currentEpochId;

    // Events
    event Staked(address indexed user, uint256 amount, uint256 epochId);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 totalAmount);

    constructor(address _honeyToken, address _bettingSystem) Ownable(msg.sender) {
        honeyToken = IERC20(_honeyToken);
        bettingSystem = _bettingSystem;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(IERC20(honeyToken).balanceOf(msg.sender) >= amount, "Insufficient balance");

        // Transfer HONEY tokens from user
        honeyToken.safeTransferFrom(msg.sender, address(this), amount);

        // Record stake
        stakes[msg.sender].push(Stake({
            amount: amount,
            epochId: currentEpochId
        }));

        // Update total staked for current epoch
        totalStakedPerEpoch[currentEpochId] += amount;

        emit Staked(msg.sender, amount, currentEpochId);
    }

    function distributeRewards(address losingContract) external {
        require(msg.sender == bettingSystem, "Only betting system can call");
        
        uint256 totalRewards = IERC20(honeyToken).balanceOf(losingContract);
        require(totalRewards > 0, "No rewards to distribute");

        // Transfer rewards from losing contract
        honeyToken.safeTransferFrom(losingContract, address(this), totalRewards);

        emit RewardsDistributed(totalRewards);
    }

    function claimRewards() external {
        uint256 totalRewards = 0;
        uint256 currentBalance = honeyToken.balanceOf(address(this));
        
        // Calculate rewards based on stake weight
        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            Stake storage userStake = stakes[msg.sender][i];
            if (userStake.amount > 0) {
                uint256 stakeWeight = (userStake.amount * 1e18) / totalStakedPerEpoch[userStake.epochId];
                uint256 reward = (currentBalance * stakeWeight) / 1e18;
                totalRewards += reward;
                userStake.amount = 0; // Reset stake after claiming
            }
        }

        require(totalRewards > 0, "No rewards to claim");
        honeyToken.safeTransfer(msg.sender, totalRewards);

        emit RewardsClaimed(msg.sender, totalRewards);
    }

    function getStakeInfo(address user) external view returns (Stake[] memory) {
        return stakes[user];
    }

    function getTotalStaked(uint256 epochId) external view returns (uint256) {
        return totalStakedPerEpoch[epochId];
    }

    function updateEpochId(uint256 newEpochId) external {
        require(msg.sender == bettingSystem, "Only betting system can call");
        currentEpochId = newEpochId;
    }
} 