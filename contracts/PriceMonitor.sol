// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract PriceMonitor is Ownable {
    IPyth public immutable pyth;
    
    // Mapping of token address to its Pyth price ID
    mapping(address => bytes32) public tokenPriceIds;
    
    // Mapping of token address to its latest price
    mapping(address => uint256) public latestPrices;
    
    // Mapping of token address to its latest price timestamp
    mapping(address => uint256) public latestPriceTimestamps;
    
    // Events
    event PriceUpdated(address indexed token, uint256 price, uint256 timestamp);
    event TokenAdded(address indexed token, bytes32 priceId);
    event TokenRemoved(address indexed token);
    
    constructor(address _pyth) Ownable(msg.sender) {
        pyth = IPyth(_pyth);
    }
    
    function addToken(address token, bytes32 priceId) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(priceId != bytes32(0), "Invalid price ID");
        require(tokenPriceIds[token] == bytes32(0), "Token already exists");
        
        tokenPriceIds[token] = priceId;
        emit TokenAdded(token, priceId);
    }
    
    function removeToken(address token) external onlyOwner {
        require(tokenPriceIds[token] != bytes32(0), "Token does not exist");
        
        delete tokenPriceIds[token];
        delete latestPrices[token];
        delete latestPriceTimestamps[token];
        
        emit TokenRemoved(token);
    }
    
    function updatePrice(address token) external {
        bytes32 priceId = tokenPriceIds[token];
        require(priceId != bytes32(0), "Token not supported");
        
        PythStructs.Price memory price = pyth.getPrice(priceId);
        require(price.publishTime > 0, "Price not available");
        
        // Convert price to 18 decimals
        int64 priceValue = price.price;
        int32 expoValue = price.expo;
        
        // Handle negative exponents
        uint256 scaledPrice;
        if (expoValue < 0) {
            scaledPrice = uint256(uint64(priceValue)) * 10**18 / uint256(uint32(-expoValue));
        } else {
            scaledPrice = uint256(uint64(priceValue)) * 10**18 * uint256(uint32(expoValue));
        }
        
        latestPrices[token] = scaledPrice;
        latestPriceTimestamps[token] = price.publishTime;
        
        emit PriceUpdated(token, scaledPrice, price.publishTime);
    }
    
    function updatePrices(address[] calldata tokens) external {
        for (uint i = 0; i < tokens.length; i++) {
            this.updatePrice(tokens[i]);
        }
    }
    
    function getTokenPrice(address token) external view returns (uint256) {
        require(tokenPriceIds[token] != bytes32(0), "Token not supported");
        return latestPrices[token];
    }
    
    function getTokenPriceTimestamp(address token) external view returns (uint256) {
        require(tokenPriceIds[token] != bytes32(0), "Token not supported");
        return latestPriceTimestamps[token];
    }
    
    function isTokenSupported(address token) external view returns (bool) {
        return tokenPriceIds[token] != bytes32(0);
    }
} 