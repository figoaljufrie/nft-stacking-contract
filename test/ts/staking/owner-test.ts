import assert from "node:assert";
import { test, beforeEach } from "node:test";
import { deployContract } from "./fixtures";

let stakingManager: any;
let owner: any;
let mockNFT: any;
let user1: any;
let rewardToken: any;

beforeEach(async () => {
  ({ stakingManager, rewardToken, owner, mockNFT, user1 } =
    await deployContract());
});

test("should allow owner to set reward rate", async () => {
  const newRate = 2000000000000000000n;
  await stakingManager.write.setRewardRate([newRate], {
    account: owner.account,
  });
  const rewardRate = await stakingManager.read.rewardRate();
  assert.equal(rewardRate, newRate);
});

test("should fail when non-owner tries to set reward rate", async () => {
  let errorCaught: any = null;

  try {
    await stakingManager.write.setRewardRate([2000000000000000000n], {
      account: user1.account,
    });
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
    normalized.includes("ownable") ||
      normalized.includes("caller is not the owner") ||
      normalized.includes("revert") ||
      normalized.includes("unknown rpc error"),
    `Expected revert for non-owner setRewardRate, but got: ${reason}`
  );
});

test("should allow owner to set NFT collection", async () => {
  await stakingManager.write.setNFTCollection([mockNFT.address], {
    account: owner.account,
  });
  const nftCollection = await stakingManager.read.nftCollection();
  assert.equal(nftCollection.toLowerCase(), mockNFT.address.toLowerCase());
});

test("should allow owner to set reward token", async () => {
  await stakingManager.write.setRewardToken([rewardToken.address], {
    account: owner.account,
  });
  const tokenAddr = await stakingManager.read.rewardToken();
  assert.equal(tokenAddr.toLowerCase(), rewardToken.address.toLowerCase());
});
