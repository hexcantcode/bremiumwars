const { ethers } = require("hardhat");

async function main() {
    const honeyTokenAddress = "0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce";
    
    // Get the contract factory for ERC20
    const ERC20 = await ethers.getContractFactory("IERC20");
    const honeyToken = await ERC20.attach(honeyTokenAddress);
    
    // Get decimals
    const decimals = await honeyToken.decimals();
    console.log("Honey token decimals:", decimals);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 