import assert from "node:assert";
import { test, beforeEach } from "node:test";
import { deployContract } from "./fixtures";

let stakingManager: any;
let user1: any;
let rewardToken: any;
let owner: any;
let user2: any;
let mockNFT: any;

beforeEach(async () => {
  ({ stakingManager, rewardToken, mockNFT, user1, user2, owner } =
    await deployContract());
});

test("should allow user to withdraw NFTs", async () => {
  await mockNFT.write.setApprovalForAll([stakingManager.address, true], {
    account: user1.account,
  });
  await stakingManager.write.stake([[0n, 1n]], { account: user1.account });

  const { viem: hreViem } = await import("hardhat").then((h) =>
    h.network.connect("hardhat")
  );
  const testClient = await hreViem.getTestClient();
  await testClient.increaseTime({ seconds: 10 });
  await testClient.mine({ blocks: 1 });

  await stakingManager.write.withdraw([[0n, 1n]], { account: user1.account });
  const [stakedTokens] = await stakingManager.read.getUserStakeInfo([
    user1.account.address,
  ]);
  assert.equal(stakedTokens.length, 0);

  const owner0 = await mockNFT.read.ownerOf([0n]);
  const owner1 = await mockNFT.read.ownerOf([1n]);
  assert.equal(owner0.toLowerCase(), user1.account.address.toLowerCase());
  assert.equal(owner1.toLowerCase(), user1.account.address.toLowerCase());
});

test("should allow emergency unstake", async () => {
  await mockNFT.write.setApprovalForAll([stakingManager.address, true], {
    account: user2.account,
  });
  await stakingManager.write.stake([[2n]], { account: user2.account });

  await stakingManager.write.emergencyUnstake([[2n]], {
    account: user2.account,
  });
  const [stakedTokens] = await stakingManager.read.getUserStakeInfo([
    user2.account.address,
  ]);
  assert.equal(stakedTokens.length, 0);
});

test("should preserve rewards after withdrawal", async () => {
  await mockNFT.write.setApprovalForAll([stakingManager.address, true], {
    account: user1.account,
  });
  await stakingManager.write.stake([[0n, 1n]], { account: user1.account });

  const { viem: hreViem } = await import("hardhat").then((h) =>
    h.network.connect("hardhat")
  );
  const testClient = await hreViem.getTestClient();
  await testClient.increaseTime({ seconds: 10 });
  await testClient.mine({ blocks: 1 });
  await stakingManager.write.withdraw([[0n, 1n]], { account: user1.account });

  const balanceBefore = await rewardToken.read.balanceOf([
    user1.account.address,
  ]);
  await stakingManager.write.claimRewards([], { account: user1.account });
  const balanceAfter = await rewardToken.read.balanceOf([
    user1.account.address,
  ]);

  const actualRate = await stakingManager.read.rewardRate();
  const expected = 2n * actualRate * 1n;
  assert.equal(balanceAfter - balanceBefore, expected);
});

test("should fail when withdrawing unstaked token", async () => {
  await mockNFT.write.setApprovalForAll([stakingManager.address, true], {
    account: user1.account,
  });

  await assert.rejects(
    async () => {
      await stakingManager.write.withdraw([[0n]], {
        account: user1.account,
      });
    },
    /Token not staked/,
    "Expected revert when withdrawing unstaked token"
  );
});