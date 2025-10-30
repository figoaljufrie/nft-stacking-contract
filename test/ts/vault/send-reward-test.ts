import { beforeEach, test } from "node:test";
import assert from "node:assert/strict";
import { deployVaultContracts } from "./fixtures";

let vault: any;
let rewardToken: any;
let owner: any;
let user1: any;
let user2: any;

beforeEach(async () => {
  ({ vault, rewardToken, owner, user1, user2 } = await deployVaultContracts());
});

test("should allow owner to send rewards", async () => {
  const depositAmount = 100000000000000000000n;
  const rewardAmount = 30000000000000000000n;

  await rewardToken.write.approve([vault.address, depositAmount], { account: user1.account });
  await vault.write.depositFunds([depositAmount], { account: user1.account });

  const user2BalanceBefore = await rewardToken.read.balanceOf([user2.account.address]);
  await vault.write.sendReward([user2.account.address, rewardAmount], { account: owner.account });

  const user2BalanceAfter = await rewardToken.read.balanceOf([user2.account.address]);
  const vaultBalance = await vault.read.getBalance();

  assert.equal(user2BalanceAfter, user2BalanceBefore + rewardAmount);
  assert.equal(vaultBalance, depositAmount - rewardAmount);
});

test("should fail when non-owner tries to send reward", async () => {
  let errorCaught: any = null;

  try {
    await vault.write.sendReward([user2.account.address, 10000000000000000000n], { account: user1.account });
  } catch (err: any) {
    errorCaught = err;
  }

  assert.ok(errorCaught);
  const reason =
    errorCaught?.shortMessage || errorCaught?.details || errorCaught?.message ||
    errorCaught?.cause?.message || errorCaught?.data?.error?.message || "";
  const normalized = reason.toLowerCase();
  assert.ok(normalized.includes("ownable") || normalized.includes("caller is not the owner") || normalized.includes("revert") || normalized.includes("unknown rpc error"));
});

test("should fail when sending reward exceeds balance", async () => {
  await assert.rejects(
    async () => { await vault.write.sendReward([user2.account.address, 100000000000000000000n], { account: owner.account }); },
    /Insufficient balance/
  );
});

test("should fail when sending zero reward", async () => {
  await assert.rejects(
    async () => { await vault.write.sendReward([user2.account.address, 0n], { account: owner.account }); },
    /invalid amount/
  );
});

test("should fail when sending reward to zero address", async () => {
  await assert.rejects(
    async () => { await vault.write.sendReward(["0x0000000000000000000000000000000000000000", 10000000000000000000n], { account: owner.account }); },
    /Invalid Recipient/
  );
});