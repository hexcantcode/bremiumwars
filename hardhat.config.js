require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-viem");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 31337
    },
    berachain: {
      url: "https://artio.rpc.berachain.com",
      chainId: 80085,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  }
}; 