import { access } from "fs";
import { network } from "hardhat";

export const REWARD_RATE = 1000000000000000000n;

export async function deployContract() {
  const { viem: hreViem } = await network.connect("hardhat");
  const wallets = await hreViem.getWalletClients();
  const [owner, user1, user2] = wallets;

  const mockNFT = await hreViem.deployContract("MockNFT", [], {
    client: { wallet: owner },
  });

  const rewardToken = await hreViem.deployContract(
    "RewardTokenUpgradeable",
    [],
    {
      client: { wallet: owner },
    }
  );

  await rewardToken.write.initialize(
    ["Reward Token", "RWT", owner.account.address],
    {
      account: owner.account,
    }
  );

  const stakingManager = await hreViem.deployContract(
    "StakingManagerUpgradeable",
    [],
    { client: { wallet: owner } }
  );

  await stakingManager.write.initialize(
    [mockNFT.address, rewardToken.address, REWARD_RATE, owner.account.address],
    { account: owner.account }
  );

  await rewardToken.write.setStakingManager([stakingManager.address], {
    account: owner.account,
  });

  await mockNFT.write.mint([user1.account.address], { account: owner.account });
  await mockNFT.write.mint([user1.account.address], {account: owner.account})
  return { owner, user1, user2, mockNFT, rewardToken, stakingManager};
}
