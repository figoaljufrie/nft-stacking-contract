import { beforeEach, test } from "node:test";
import assert from "node:assert";
import { deployContract } from "./fixtures";

let rewardToken: any;
let owner: any;
let stakingManager: any;
let user1: any;

beforeEach(async () => {
  ({ rewardToken, owner, stakingManager, user1 } = await deployContract());
});

test("should allow owner to pause contract", async () => {
  await rewardToken.write.pause([], { account: owner.account });
  const paused = await rewardToken.read.paused();
  assert.equal(paused, true);
});

test("should allow owner to unpause contract", async () => {
  await rewardToken.write.pause([], {
    account: owner.account,
  });

  await rewardToken.write.unpause([], {
    account: owner.account,
  });

  const paused = await rewardToken.read.paused();
  assert.equal(paused, false);
});

test("should fail when non-owner tries to pause", async () => {
  let errorCaught = null;

  try {
    await rewardToken.write.pause([], {
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
    `Expected revert for non-owner pause, but got: ${reason}`
  );
});
