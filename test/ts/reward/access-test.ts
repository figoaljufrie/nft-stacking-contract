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

test("should allow owner to set staking manager", async () => {
  await rewardToken.write.setStakingManager([stakingManager.address], {
    account: owner.account,
  });

  const manager = await rewardToken.read.stakingManager();
  assert.equal(
    manager.toLowerCase(),
    stakingManager.address.toLowerCase()
  );
});

test("should fail when non-owner tries to set staking manager", async () => {
  let errorCaught = null;

  try {
    await rewardToken.write.setStakingManager(
      [stakingManager.address],
      {
        account: user1.account,
      }
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
    normalized.includes("ownable") ||
      normalized.includes("caller is not the owner") ||
      normalized.includes("revert") ||
      normalized.includes("unknown rpc error"),
    `Expected revert for non-owner setStakingManager, but got: ${reason}`
  );
});

test("should fail when setting zero address as staking manager", async () => {
  await assert.rejects(
    async () => {
      await rewardToken.write.setStakingManager(
        ["0x0000000000000000000000000000000000000000"],
        {
          account: owner.account,
        }
      );
    },
    /Invalid manager address/,
    "Expected revert when setting zero address"
  );
});