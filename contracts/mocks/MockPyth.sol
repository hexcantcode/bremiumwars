// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract MockPyth is IPyth {
    mapping(bytes32 => PythStructs.Price) private prices;
    uint256 private constant VALID_TIME_PERIOD = 60; // 60 seconds

    function setPrice(bytes32 priceId, uint64 price) external {
        prices[priceId] = PythStructs.Price({
            price: int64(price),
            conf: 1,
            expo: -8,
            publishTime: uint64(block.timestamp)
        });
    }

    function getPrice(bytes32 id) external view override returns (PythStructs.Price memory) {
        require(block.timestamp <= prices[id].publishTime + VALID_TIME_PERIOD, "Price too old");
        return prices[id];
    }

    function getPriceNoOlderThan(bytes32 id, uint256 age) external view override returns (PythStructs.Price memory) {
        require(block.timestamp <= prices[id].publishTime + age, "Price too old");
        return prices[id];
    }

    function getEmaPrice(bytes32 id) external view override returns (PythStructs.Price memory) {
        require(block.timestamp <= prices[id].publishTime + VALID_TIME_PERIOD, "Price too old");
        return prices[id];
    }

    function getEmaPriceNoOlderThan(bytes32 id, uint256 age) external view override returns (PythStructs.Price memory) {
        require(block.timestamp <= prices[id].publishTime + age, "Price too old");
        return prices[id];
    }

    function getPriceUnsafe(bytes32 id) external view override returns (PythStructs.Price memory) {
        return prices[id];
    }

    function getEmaPriceUnsafe(bytes32 id) external view override returns (PythStructs.Price memory) {
        return prices[id];
    }

    function getValidTimePeriod() external pure override returns (uint validTimePeriod) {
        return VALID_TIME_PERIOD;
    }

    function updatePriceFeeds(bytes[] calldata updateData) external payable override {
        // Do nothing in mock
    }

    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable override {
        // Do nothing in mock
    }

    function getUpdateFee(bytes[] calldata updateData) external pure override returns (uint256) {
        return 0;
    }

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable override returns (PythStructs.PriceFeed[] memory) {
        return new PythStructs.PriceFeed[](0);
    }

    function parsePriceFeedUpdatesUnique(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable override returns (PythStructs.PriceFeed[] memory) {
        return new PythStructs.PriceFeed[](0);
    }
} 