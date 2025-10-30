import { beforeEach, test } from "node:test";
import assert from "node:assert/strict";
import { network } from "hardhat";

let rewardToken: any;
let owner: any;
let stakingManager: any;
let user1: any;

beforeEach(async () => {
  const { viem: hreViem } = await network.connect("hardhat");
  const wallets = await hreViem.getWalletClients();
  [owner, stakingManager, user1] = wallets;

  rewardToken = await hreViem.deployContract("RewardTokenUpgradeable", [], {
    client: { wallet: owner },
  });

  await rewardToken.write.initialize(
    ["Reward Token", "RWT", owner.account.address],
    { account: owner.account }
  );

  await rewardToken.write.setStakingManager([stakingManager.account.address], {
    account: owner.account,
  });
});

test("should allow staking manager to mint tokens", async () => {
  await rewardToken.write.mint([user1.account.address, 1000000000000000000n], {
    account: stakingManager.account,
  });

  const user1Balance = await rewardToken.read.balanceOf([user1.account.address]);
  assert.equal(user1Balance, 1000000000000000000n);
});

test("should fail when non-staking-manager tries to mint", async () => {
  await assert.rejects(
    async () => {
      await rewardToken.write.mint([user1.account.address, 1000000000000000000n], {
        account: user1.account,
      });
    },
    /Not Authorized/
  );
});

test("should fail when minting beyond max supply", async () => {
  const excessAmount = 9000001000000000000000000n;
  await assert.rejects(
    async () => {
      await rewardToken.write.mint([user1.account.address, excessAmount], {
        account: stakingManager.account,
      });
    },
    /Exceeds max supply/
  );
});

test("should block minting when paused", async () => {
  await rewardToken.write.setStakingManager([stakingManager.account.address], {
    account: owner.account,
  });

  await rewardToken.write.pause([], {
    account: owner.account,
  });

  let errorCaught = null;

  try {
    await rewardToken.write.mint(
      [user1.account.address, 1000000000000000000n],
      { account: stakingManager.account }
    );
  } catch (err: any) {
    errorCaught = err;
  }

  assert.ok(errorCaught, "Expected a revert but no error was thrown");

  const reason =
    errorCaught?.shortMessage ||
    errorCaught?.details ||
    errorCaught?.message ||
    errorCaught?.cause?.message ||
    errorCaught?.data?.error?.message ||
    "";

  const normalized = reason.toLowerCase();

  assert.ok(
    normalized.includes("paused") ||
      normalized.includes("pausable") ||
      normalized.includes("revert") ||
      normalized.includes("unknown rpc error"),
    `Expected revert for paused minting, but got: ${reason}`
  );
});