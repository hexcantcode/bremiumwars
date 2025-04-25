const { ethers } = require("hardhat");

async function main() {
    // Get the contract factories
    const BettingSystem = await ethers.getContractFactory("BettingSystem");
    const TokenStaking = await ethers.getContractFactory("TokenStaking");

    // HONEY token address
    const honeyTokenAddress = "0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce";

    // Deploy betting system
    const bettingSystem = await BettingSystem.deploy(honeyTokenAddress);
    await bettingSystem.deployed();
    console.log("BettingSystem deployed to:", bettingSystem.address);

    // Deploy staking contracts for each token
    const tokens = [
        "iBGT",
        "LBGT",
        "stBGT"
    ];

    for (const token of tokens) {
        // Deploy UP staking contract
        const upStaking = await TokenStaking.deploy(honeyTokenAddress, bettingSystem.address);
        await upStaking.deployed();
        console.log(`${token} UP Staking deployed to:`, upStaking.address);

        // Deploy DOWN staking contract
        const downStaking = await TokenStaking.deploy(honeyTokenAddress, bettingSystem.address);
        await downStaking.deployed();
        console.log(`${token} DOWN Staking deployed to:`, downStaking.address);

        // Add token to betting system
        await bettingSystem.addToken(
            token,
            upStaking.address,
            downStaking.address
        );
        console.log(`${token} added to betting system`);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 