// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenStaking.sol";

contract BettingSystem is Ownable {
    struct Epoch {
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isSettled;
        mapping(address => uint256) tokenPrices; // token address => price in BERA
    }

    struct TokenInfo {
        address upStakingContract;
        address downStakingContract;
        bool isActive;
    }

    // Constants
    uint256 public constant EPOCH_DURATION = 7 days;
    uint256 public constant MIN_STAKE_AMOUNT = 1 ether; // 1 HONEY token

    // State variables
    mapping(uint256 => Epoch) public epochs;
    mapping(address => TokenInfo) public supportedTokens;
    address[] public activeTokens;
    uint256 public currentEpochId;
    IERC20 public honeyToken;

    // Events
    event EpochStarted(uint256 indexed epochId, uint256 startTime, uint256 endTime);
    event EpochEnded(uint256 indexed epochId, uint256 endTime);
    event PriceUpdated(uint256 indexed epochId, address indexed token, uint256 price);
    event RewardsDistributed(uint256 indexed epochId, address indexed token, bool isUp);
    event TokenAdded(address indexed token, address upStakingContract, address downStakingContract);
    event TokenRemoved(address indexed token);

    constructor(address _honeyToken) {
        honeyToken = IERC20(_honeyToken);
        currentEpochId = 1;
        _startNewEpoch();
    }

    function _startNewEpoch() internal {
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + EPOCH_DURATION;
        
        epochs[currentEpochId].startTime = startTime;
        epochs[currentEpochId].endTime = endTime;
        epochs[currentEpochId].isActive = true;
        epochs[currentEpochId].isSettled = false;

        emit EpochStarted(currentEpochId, startTime, endTime);
    }

    function addToken(address token, address upStakingContract, address downStakingContract) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(upStakingContract != address(0), "Invalid up staking contract");
        require(downStakingContract != address(0), "Invalid down staking contract");
        require(!supportedTokens[token].isActive, "Token already added");

        supportedTokens[token] = TokenInfo({
            upStakingContract: upStakingContract,
            downStakingContract: downStakingContract,
            isActive: true
        });

        activeTokens.push(token);
        emit TokenAdded(token, upStakingContract, downStakingContract);
    }

    function removeToken(address token) external onlyOwner {
        require(supportedTokens[token].isActive, "Token not active");
        
        supportedTokens[token].isActive = false;
        
        // Remove from active tokens array
        for (uint256 i = 0; i < activeTokens.length; i++) {
            if (activeTokens[i] == token) {
                activeTokens[i] = activeTokens[activeTokens.length - 1];
                activeTokens.pop();
                break;
            }
        }

        emit TokenRemoved(token);
    }

    function updatePrices(address[] calldata tokens, uint256[] calldata prices) external onlyOwner {
        require(epochs[currentEpochId].isActive, "No active epoch");
        require(tokens.length == prices.length, "Array lengths mismatch");

        for (uint256 i = 0; i < tokens.length; i++) {
            require(supportedTokens[tokens[i]].isActive, "Token not supported");
            epochs[currentEpochId].tokenPrices[tokens[i]] = prices[i];
            emit PriceUpdated(currentEpochId, tokens[i], prices[i]);
        }
    }

    function endEpoch() external onlyOwner {
        require(epochs[currentEpochId].isActive, "No active epoch");
        require(block.timestamp >= epochs[currentEpochId].endTime, "Epoch not ended");

        epochs[currentEpochId].isActive = false;
        epochs[currentEpochId].isSettled = true;

        emit EpochEnded(currentEpochId, block.timestamp);

        // Distribute rewards for each token
        for (uint256 i = 0; i < activeTokens.length; i++) {
            address token = activeTokens[i];
            if (supportedTokens[token].isActive) {
                _distributeRewards(token);
            }
        }

        // Start new epoch
        currentEpochId++;
        _startNewEpoch();
    }

    function _distributeRewards(address token) internal {
        uint256 currentPrice = epochs[currentEpochId].tokenPrices[token];
        uint256 previousPrice = epochs[currentEpochId - 1].tokenPrices[token];
        
        bool isUp = currentPrice > previousPrice;
        
        address winningContract = isUp ? 
            supportedTokens[token].upStakingContract : 
            supportedTokens[token].downStakingContract;
            
        address losingContract = isUp ? 
            supportedTokens[token].downStakingContract : 
            supportedTokens[token].upStakingContract;

        // Distribute rewards
        TokenStaking(winningContract).distributeRewards(losingContract);
        
        emit RewardsDistributed(currentEpochId, token, isUp);
    }

    function getTokenPrice(uint256 epochId, address token) external view returns (uint256) {
        return epochs[epochId].tokenPrices[token];
    }

    function getActiveTokens() external view returns (address[] memory) {
        return activeTokens;
    }

    function getEpochInfo(uint256 epochId) external view returns (
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        bool isSettled
    ) {
        Epoch storage epoch = epochs[epochId];
        return (
            epoch.startTime,
            epoch.endTime,
            epoch.isActive,
            epoch.isSettled
        );
    }
} 