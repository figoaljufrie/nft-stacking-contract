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

test("should allow token transfers", async () => {
  const transferAmount = 1000000000000000000n;
  await rewardToken.write.transfer([user1.account.address, transferAmount], {
    account: owner.account,
  });
  const user1Balance = await rewardToken.read.balanceOf([
    user1.account.address,
  ]);
  assert.equal(user1Balance, transferAmount);
});

test("should allow approve and transferFrom", async () => {
  const approveAmount = 1000000000000000000n;
  const transferAmount = 500000000000000000n;

  await rewardToken.write.approve([user1.account.address, approveAmount], {
    account: owner.account,
  });
  const allowance = await rewardToken.read.allowance([
    owner.account.address,
    user1.account.address,
  ]);
  assert.equal(allowance, approveAmount);
  await rewardToken.write.transferFrom(
    [owner.account.address, user1.account.address, transferAmount],
    {
      account: user1.account,
    }
  );

  const user1balance = await rewardToken.read.balanceOf([
    user1.account.address,
  ]);
  assert.equal(user1balance, transferAmount);
});

test("should have 18 decimals", async () => {
  const decimals = await rewardToken.read.decimals();
  assert.equal(decimals, 18);
});

test("should block transfers when paused", async () => {
  await rewardToken.write.transfer(
    [user1.account.address, 1000000000000000000n],
    { account: owner.account }
  );

  await rewardToken.write.pause([], {
    account: owner.account,
  });

  let errorCaught = null;

  try {
    await rewardToken.write.transfer(
      [owner.account.address, 500000000000000000n],
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
    normalized.includes("paused") ||
      normalized.includes("pausable") ||
      normalized.includes("revert") ||
      normalized.includes("unknown rpc error"),
    `Expected revert for paused transfer, but got: ${reason}`
  );
});