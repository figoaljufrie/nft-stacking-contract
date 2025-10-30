import { network } from "hardhat";

export async function deployVaultContracts() {
  const { viem: hreViem } = await network.connect("hardhat");
  const wallets = await hreViem.getWalletClients();

  const [owner, user1, user2] = wallets;

  // Deploy MockRewardToken
  const rewardToken = await hreViem.deployContract("MockRewardToken", [], {
    client: { wallet: owner },
  });

  // Deploy TreasuryVault
  const vault = await hreViem.deployContract("TreasuryVault", [], {
    client: { wallet: owner },
  });

  // Initialize vault
  await vault.write.initialize([rewardToken.address, owner.account.address], {
    account: owner.account,
  });

  // Mint tokens to users
  const mintAmount = 1000000000000000000000n;
  await rewardToken.write.mint([user1.account.address, mintAmount], {
    account: owner.account,
  });
  await rewardToken.write.mint([user2.account.address, mintAmount], {
    account: owner.account,
  });

  return { vault, rewardToken, owner, user1, user2 };
}