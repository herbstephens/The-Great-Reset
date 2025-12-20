require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000001";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
const BASESCAN_API_KEY = process.env.BASESCAN_API_KEY || "";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    hardhat: {
      chainId: 31337,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    // World Chain
    "worldchain": {
      url: "https://worldchain-mainnet.g.alchemy.com/public",
      chainId: 480,
      accounts: [PRIVATE_KEY],
    },
    "worldchain-sepolia": {
      url: "https://worldchain-sepolia.g.alchemy.com/public",
      chainId: 4801,
      accounts: [PRIVATE_KEY],
    },
    // Base
    "base": {
      url: "https://mainnet.base.org",
      chainId: 8453,
      accounts: [PRIVATE_KEY],
    },
    "base-sepolia": {
      url: "https://sepolia.base.org",
      chainId: 84532,
      accounts: [PRIVATE_KEY],
    },
    // Ethereum
    "mainnet": {
      url: process.env.MAINNET_RPC_URL || "https://eth.llamarpc.com",
      chainId: 1,
      accounts: [PRIVATE_KEY],
    },
    "sepolia": {
      url: process.env.SEPOLIA_RPC_URL || "https://rpc.sepolia.org",
      chainId: 11155111,
      accounts: [PRIVATE_KEY],
    },
    // Optimism
    "optimism": {
      url: "https://mainnet.optimism.io",
      chainId: 10,
      accounts: [PRIVATE_KEY],
    },
    "optimism-sepolia": {
      url: "https://sepolia.optimism.io",
      chainId: 11155420,
      accounts: [PRIVATE_KEY],
    },
    // Arbitrum
    "arbitrum": {
      url: "https://arb1.arbitrum.io/rpc",
      chainId: 42161,
      accounts: [PRIVATE_KEY],
    },
    "arbitrum-sepolia": {
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      chainId: 421614,
      accounts: [PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY,
      sepolia: ETHERSCAN_API_KEY,
      base: BASESCAN_API_KEY,
      "base-sepolia": BASESCAN_API_KEY,
      optimisticEthereum: process.env.OPTIMISM_API_KEY || "",
      arbitrumOne: process.env.ARBISCAN_API_KEY || "",
    },
    customChains: [
      {
        network: "worldchain",
        chainId: 480,
        urls: {
          apiURL: "https://worldchain-mainnet.explorer.alchemy.com/api",
          browserURL: "https://worldchain-mainnet.explorer.alchemy.com",
        },
      },
      {
        network: "worldchain-sepolia",
        chainId: 4801,
        urls: {
          apiURL: "https://worldchain-sepolia.explorer.alchemy.com/api",
          browserURL: "https://worldchain-sepolia.explorer.alchemy.com",
        },
      },
    ],
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};
