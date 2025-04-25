// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenStaking.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract BettingSystem is Ownable {
    struct Epoch {
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isSettled;
        mapping(address => uint256) tokenPrices; // token address => price in BERA
        mapping(address => uint256) tokenPremiums; // token address => premium percentage
    }

    struct TokenInfo {
        address upStakingContract;
        address downStakingContract;
        bytes32 pythPriceId;
        bool isActive;
    }

    // Constants
    uint256 public constant EPOCH_DURATION = 1 days;
    uint256 public constant MIN_STAKE_AMOUNT = 1 * 10**18; // 1 HONEY token (18 decimals)

    // State variables
    mapping(uint256 => Epoch) public epochs;
    mapping(address => TokenInfo) public supportedTokens;
    address[] public activeTokens;
    uint256 public currentEpochId;
    IERC20 public honeyToken;
    IPyth public pyth;

    // Events
    event EpochStarted(uint256 indexed epochId, uint256 startTime, uint256 endTime);
    event EpochEnded(uint256 indexed epochId, uint256 endTime);
    event PriceUpdated(uint256 indexed epochId, address indexed token, uint256 price);
    event PremiumUpdated(uint256 indexed epochId, address indexed token, uint256 premium);
    event RewardsDistributed(uint256 indexed epochId, address indexed token, bool isUp);
    event TokenAdded(address indexed token, address upStakingContract, address downStakingContract, bytes32 pythPriceId);
    event TokenRemoved(address indexed token);

    constructor(address _honeyToken, address _pyth) Ownable(msg.sender) {
        honeyToken = IERC20(_honeyToken);
        pyth = IPyth(_pyth);
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

    function addToken(
        address token, 
        address upStakingContract, 
        address downStakingContract,
        bytes32 pythPriceId
    ) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(upStakingContract != address(0), "Invalid up staking contract");
        require(downStakingContract != address(0), "Invalid down staking contract");
        require(!supportedTokens[token].isActive, "Token already added");

        supportedTokens[token] = TokenInfo({
            upStakingContract: upStakingContract,
            downStakingContract: downStakingContract,
            pythPriceId: pythPriceId,
            isActive: true
        });

        activeTokens.push(token);
        emit TokenAdded(token, upStakingContract, downStakingContract, pythPriceId);
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

    function updatePrices() public {
        require(epochs[currentEpochId].isActive, "No active epoch");
        
        // Get BERA price from Pyth
        bytes32 beraPriceId = supportedTokens[address(0)].pythPriceId;
        PythStructs.Price memory beraPrice = pyth.getPrice(beraPriceId);
        uint256 beraPriceValue = uint256(uint64(beraPrice.price));
        epochs[currentEpochId].tokenPrices[address(0)] = beraPriceValue;

        // Update prices for all tokens
        for (uint256 i = 0; i < activeTokens.length; i++) {
            address token = activeTokens[i];
            if (supportedTokens[token].isActive) {
                bytes32 priceId = supportedTokens[token].pythPriceId;
                PythStructs.Price memory price = pyth.getPrice(priceId);
                uint256 priceValue = uint256(uint64(price.price));
                
                epochs[currentEpochId].tokenPrices[token] = priceValue;
                emit PriceUpdated(currentEpochId, token, priceValue);

                // Calculate premium
                uint256 premium = ((priceValue * 100) / beraPriceValue) - 100;
                epochs[currentEpochId].tokenPremiums[token] = premium;
                emit PremiumUpdated(currentEpochId, token, premium);
            }
        }
    }

    function endEpoch() external {
        require(epochs[currentEpochId].isActive, "No active epoch");
        require(block.timestamp >= epochs[currentEpochId].endTime, "Epoch not ended");

        // Update final prices before ending epoch
        updatePrices();

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
        uint256 currentPremium = epochs[currentEpochId].tokenPremiums[token];
        uint256 previousPremium = epochs[currentEpochId - 1].tokenPremiums[token];
        
        bool isUp = currentPremium > previousPremium;
        
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

    function getTokenPremium(uint256 epochId, address token) external view returns (uint256) {
        return epochs[epochId].tokenPremiums[token];
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