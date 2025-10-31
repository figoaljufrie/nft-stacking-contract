import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "viem";

// Module 1: Deploy NFT (non-upgradeable)
const NFTModule = buildModule("NFTModule", (m) => {
  const initialOwner = m.getParameter("initialOwner", m.getAccount(0));
  const nftMintPrice = m.getParameter("nftMintPrice", parseEther("0.01"));

  const myNFT = m.contract("MyNFT", [initialOwner]);

  m.call(myNFT, "setMintPrice", [nftMintPrice]);

  return { myNFT };
});

// Module 2: Deploy RewardToken with UUPS Proxy
const RewardTokenModule = buildModule("RewardTokenModule", (m) => {
  const initialOwner = m.getParameter("initialOwner", m.getAccount(0));
  const rewardTokenName = m.getParameter("rewardTokenName", "RewardToken");
  const rewardTokenSymbol = m.getParameter("rewardTokenSymbol", "RWT");

  // Step 1: Deploy implementation
  const rewardTokenImpl = m.contract("RewardTokenUpgradeable");

  // Step 2: Encode initialize call
  const initData = m.encodeFunctionCall(rewardTokenImpl, "initialize", [
    rewardTokenName,
    rewardTokenSymbol,
    initialOwner,
  ]);

  // Step 3: Deploy proxy with implementation and init data
  const rewardTokenProxy = m.contract("ERC1967Proxy", [
    rewardTokenImpl,
    initData,
  ]);

  // Step 4: Create interface to interact with proxy using implementation ABI
  const rewardToken = m.contractAt("RewardTokenUpgradeable", rewardTokenProxy, {
    id: "RewardToken_Proxy_Interface",
  });

  return {
    rewardToken,
    rewardTokenImpl,
    rewardTokenProxy,
  };
});

// Module 3: Deploy StakingManager with UUPS Proxy
const StakingManagerModule = buildModule("StakingManagerModule", (m) => {
  const initialOwner = m.getParameter("initialOwner", m.getAccount(0));
  const rewardRate = m.getParameter("rewardRate", parseEther("0.001"));

  // Import previous modules
  const { myNFT } = m.useModule(NFTModule);
  const { rewardToken } = m.useModule(RewardTokenModule);

  // Step 1: Deploy implementation
  const stakingManagerImpl = m.contract("StakingManagerUpgradeable");

  // Step 2: Encode initialize call
  const initData = m.encodeFunctionCall(stakingManagerImpl, "initialize", [
    myNFT,
    rewardToken,
    rewardRate,
    initialOwner,
  ]);

  // Step 3: Deploy proxy
  const stakingManagerProxy = m.contract("ERC1967Proxy", [
    stakingManagerImpl,
    initData,
  ]);

  // Step 4: Create interface
  const stakingManager = m.contractAt(
    "StakingManagerUpgradeable",
    stakingManagerProxy,
    {
      id: "StakingManager_Proxy_Interface",
    }
  );

  return {
    stakingManager,
    stakingManagerImpl,
    stakingManagerProxy,
  };
});

// Module 4: Deploy TreasuryVault with UUPS Proxy
const TreasuryVaultModule = buildModule("TreasuryVaultModule", (m) => {
  const initialOwner = m.getParameter("initialOwner", m.getAccount(0));

  const { rewardToken } = m.useModule(RewardTokenModule);

  // Step 1: Deploy implementation
  const treasuryVaultImpl = m.contract("TreasuryVault");

  // Step 2: Encode initialize call
  const initData = m.encodeFunctionCall(treasuryVaultImpl, "initialize", [
    rewardToken,
    initialOwner,
  ]);

  // Step 3: Deploy proxy
  const treasuryVaultProxy = m.contract("ERC1967Proxy", [
    treasuryVaultImpl,
    initData,
  ]);

  // Step 4: Create interface
  const treasuryVault = m.contractAt("TreasuryVault", treasuryVaultProxy, {
    id: "TreasuryVault_Proxy_Interface",
  });

  return {
    treasuryVault,
    treasuryVaultImpl,
    treasuryVaultProxy,
  };
});

// Module 5: Configure connections between contracts
const ConfigurationModule = buildModule("ConfigurationModule", (m) => {
  const { rewardToken } = m.useModule(RewardTokenModule);
  const { stakingManager } = m.useModule(StakingManagerModule);

  // Allow StakingManager to mint reward tokens
  m.call(rewardToken, "setStakingManager", [stakingManager]);

  return {};
});

// Main deployment module that orchestrates everything
const MainDeploymentModule = buildModule("MainDeploymentModule", (m) => {
  const { myNFT } = m.useModule(NFTModule);
  const { rewardToken, rewardTokenImpl, rewardTokenProxy } =
    m.useModule(RewardTokenModule);
  const { stakingManager, stakingManagerImpl, stakingManagerProxy } =
    m.useModule(StakingManagerModule);
  const { treasuryVault, treasuryVaultImpl, treasuryVaultProxy } =
    m.useModule(TreasuryVaultModule);

  // Ensure configuration runs after all deployments
  m.useModule(ConfigurationModule);

  return {
    // User-facing contracts (use these addresses in your frontend)
    myNFT,
    rewardToken,
    stakingManager,
    treasuryVault,

    // Implementation contracts (for future upgrades)
    rewardTokenImpl,
    stakingManagerImpl,
    treasuryVaultImpl,

    // Proxy contracts (the actual deployed addresses users interact with)
    rewardTokenProxy,
    stakingManagerProxy,
    treasuryVaultProxy,
  };
});

export default MainDeploymentModule;
