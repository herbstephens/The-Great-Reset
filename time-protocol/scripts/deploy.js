const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  
  console.log("Deploying TIME Protocol contracts with account:", deployer.address);
  console.log("Account balance:", (await deployer.provider.getBalance(deployer.address)).toString());
  console.log("Network:", hre.network.name);
  console.log("");

  // Configuration per network
  const config = {
    // World Chain Mainnet
    "worldchain": {
      worldId: "0x...", // TODO: Add World ID Router address
      dividendToken: "0x...", // USDC on World Chain
      appId: "app_time_protocol",
      actionId: "verify_human",
      groupId: 1,
    },
    // World Chain Sepolia (Testnet)
    "worldchain-sepolia": {
      worldId: "0x11cA3127182f7583EfC416a8771BD4d11Fae4334", // World ID Router on Sepolia
      dividendToken: "0x...", // Test USDC
      appId: "app_time_protocol_test",
      actionId: "verify_human",
      groupId: 1,
    },
    // Base Mainnet
    "base": {
      worldId: "0x...",
      dividendToken: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", // USDC on Base
      appId: "app_time_protocol",
      actionId: "verify_human",
      groupId: 1,
    },
    // Base Sepolia
    "base-sepolia": {
      worldId: "0x...",
      dividendToken: "0x...",
      appId: "app_time_protocol_test",
      actionId: "verify_human",
      groupId: 1,
    },
    // Local/Hardhat
    "hardhat": {
      worldId: "0x0000000000000000000000000000000000000001",
      dividendToken: "0x0000000000000000000000000000000000000002",
      appId: "app_time_protocol_local",
      actionId: "verify_human",
      groupId: 1,
    },
    "localhost": {
      worldId: "0x0000000000000000000000000000000000000001",
      dividendToken: "0x0000000000000000000000000000000000000002",
      appId: "app_time_protocol_local",
      actionId: "verify_human",
      groupId: 1,
    },
  };

  const networkConfig = config[hre.network.name];
  if (!networkConfig) {
    throw new Error(`No configuration found for network: ${hre.network.name}`);
  }

  // 1. Deploy TIMEToken
  console.log("1. Deploying TIMEToken...");
  const TIMEToken = await hre.ethers.getContractFactory("TIMEToken");
  const timeToken = await TIMEToken.deploy();
  await timeToken.waitForDeployment();
  const timeTokenAddress = await timeToken.getAddress();
  console.log("   TIMEToken deployed to:", timeTokenAddress);

  // 2. Deploy WorkReceipt
  console.log("2. Deploying WorkReceipt...");
  const WorkReceipt = await hre.ethers.getContractFactory("WorkReceipt");
  const workReceipt = await WorkReceipt.deploy();
  await workReceipt.waitForDeployment();
  const workReceiptAddress = await workReceipt.getAddress();
  console.log("   WorkReceipt deployed to:", workReceiptAddress);

  // 3. Deploy UniversalCalendar
  console.log("3. Deploying UniversalCalendar...");
  const UniversalCalendar = await hre.ethers.getContractFactory("UniversalCalendar");
  const calendar = await UniversalCalendar.deploy(
    networkConfig.worldId,
    networkConfig.appId,
    networkConfig.actionId,
    networkConfig.groupId
  );
  await calendar.waitForDeployment();
  const calendarAddress = await calendar.getAddress();
  console.log("   UniversalCalendar deployed to:", calendarAddress);

  // 4. Deploy CommonsDistributor
  console.log("4. Deploying CommonsDistributor...");
  const CommonsDistributor = await hre.ethers.getContractFactory("CommonsDistributor");
  const distributor = await CommonsDistributor.deploy(
    calendarAddress,
    networkConfig.dividendToken
  );
  await distributor.waitForDeployment();
  const distributorAddress = await distributor.getAddress();
  console.log("   CommonsDistributor deployed to:", distributorAddress);

  // 5. Deploy TIMEMarketplace
  console.log("5. Deploying TIMEMarketplace...");
  const TIMEMarketplace = await hre.ethers.getContractFactory("TIMEMarketplace");
  const marketplace = await TIMEMarketplace.deploy(
    calendarAddress,
    networkConfig.dividendToken, // Using same token for payments
    deployer.address // Fee recipient
  );
  await marketplace.waitForDeployment();
  const marketplaceAddress = await marketplace.getAddress();
  console.log("   TIMEMarketplace deployed to:", marketplaceAddress);

  // 6. Configure contracts
  console.log("\n6. Configuring contracts...");
  
  // Set TIMEToken address in Calendar
  await calendar.setTIMEToken(timeTokenAddress);
  console.log("   Set TIMEToken in UniversalCalendar");
  
  // Set WorkReceipt address in Calendar
  await calendar.setWorkReceipt(workReceiptAddress);
  console.log("   Set WorkReceipt in UniversalCalendar");
  
  // Grant MINTER_ROLE to Calendar in TIMEToken
  const MINTER_ROLE = await timeToken.MINTER_ROLE();
  await timeToken.grantRole(MINTER_ROLE, calendarAddress);
  console.log("   Granted MINTER_ROLE to UniversalCalendar in TIMEToken");
  
  // Grant MINTER_ROLE to Calendar in WorkReceipt
  await workReceipt.grantRole(MINTER_ROLE, calendarAddress);
  console.log("   Granted MINTER_ROLE to UniversalCalendar in WorkReceipt");

  // Summary
  console.log("\n" + "=".repeat(60));
  console.log("DEPLOYMENT COMPLETE");
  console.log("=".repeat(60));
  console.log("\nContract Addresses:");
  console.log(`  TIMEToken:          ${timeTokenAddress}`);
  console.log(`  WorkReceipt:        ${workReceiptAddress}`);
  console.log(`  UniversalCalendar:  ${calendarAddress}`);
  console.log(`  CommonsDistributor: ${distributorAddress}`);
  console.log(`  TIMEMarketplace:    ${marketplaceAddress}`);
  console.log("\nNetwork:", hre.network.name);
  console.log("Deployer:", deployer.address);
  
  // Save deployment addresses
  const fs = require("fs");
  const deploymentData = {
    network: hre.network.name,
    timestamp: new Date().toISOString(),
    deployer: deployer.address,
    contracts: {
      TIMEToken: timeTokenAddress,
      WorkReceipt: workReceiptAddress,
      UniversalCalendar: calendarAddress,
      CommonsDistributor: distributorAddress,
      TIMEMarketplace: marketplaceAddress,
    },
    config: networkConfig,
  };
  
  const deploymentsDir = "./deployments";
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }
  
  fs.writeFileSync(
    `${deploymentsDir}/${hre.network.name}.json`,
    JSON.stringify(deploymentData, null, 2)
  );
  console.log(`\nDeployment saved to: ${deploymentsDir}/${hre.network.name}.json`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
