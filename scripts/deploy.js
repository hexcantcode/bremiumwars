const { ethers } = require("hardhat");

async function main() {
    // Get the contract factories
    const BettingSystem = await ethers.getContractFactory("BettingSystem");
    const TokenStaking = await ethers.getContractFactory("TokenStaking");

    // Contract addresses
    const honeyTokenAddress = "0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce";
    const pythAddress = "0x2880aB155794e7179c9eE2e38200202908C17B43";

    // Pyth Price Feed IDs
    const pythPriceIds = {
        BERA: "0x962088abcfdbdb6e30db2e340c8cf887d9efb311b1f2f17b155a63dbb6d40265",
        iBGT: "0xc929105a1af143cbfc887c4573947f54422a9ca88a9e622d151b8abdf5c2962f",
        LBGT: "0x7d80a0d7344c6632c5ed2b85016f32aed4f831294e274739d92bb9e32df5b22f",
        stBGT: "0xffd5448b844f5e7eeafbf36c47c7d4791a3cb86f5cefe02a7ba7864b22d81137"
    };

    // Deploy betting system
    const bettingSystem = await BettingSystem.deploy(honeyTokenAddress, pythAddress);
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

        // Add token to betting system with Pyth price ID
        await bettingSystem.addToken(
            token,
            upStaking.address,
            downStaking.address,
            pythPriceIds[token]
        );
        console.log(`${token} added to betting system`);
    }

    // Verify contracts on Berachain explorer
    console.log("\nVerifying contracts...");
    await hre.run("verify:verify", {
        address: bettingSystem.address,
        constructorArguments: [honeyTokenAddress, pythAddress],
    });

    for (const token of tokens) {
        const upStaking = await TokenStaking.attach(upStakingAddresses[token]);
        const downStaking = await TokenStaking.attach(downStakingAddresses[token]);

        await hre.run("verify:verify", {
            address: upStaking.address,
            constructorArguments: [honeyTokenAddress, bettingSystem.address],
        });

        await hre.run("verify:verify", {
            address: downStaking.address,
            constructorArguments: [honeyTokenAddress, bettingSystem.address],
        });
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 