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

test("should allow owner to pause vault", async () => {
  await vault.write.pause([], { account: owner.account });
  const paused = await vault.read.paused();
  assert.equal(paused, true);
});

test("should allow owner to unpause vault", async () => {
  await vault.write.pause([], { account: owner.account });
  await vault.write.unpause([], { account: owner.account });
  const paused = await vault.read.paused();
  assert.equal(paused, false);
});

test("should fail when non-owner tries to pause", async () => {
  let errorCaught: any = null;

  try {
    await vault.write.pause([], { account: user1.account });
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

test("should fail when depositing while paused", async () => {
  await vault.write.pause([], { account: owner.account });
  await rewardToken.write.approve([vault.address, 100000000000000000000n], { account: user1.account });

  await assert.rejects(
    async () => { await vault.write.depositFunds([100000000000000000000n], { account: user1.account }); },
    /Vault is paused/
  );
});

test("should fail when sending reward while paused", async () => {
  await rewardToken.write.approve([vault.address, 100000000000000000000n], { account: user1.account });
  await vault.write.depositFunds([100000000000000000000n], { account: user1.account });
  await vault.write.pause([], { account: owner.account });

  await assert.rejects(
    async () => { await vault.write.sendReward([user2.account.address, 10000000000000000000n], { account: owner.account }); },
    /Vault is paused/
  );
});

test("should allow owner to withdraw even when paused", async () => {
  await rewardToken.write.approve([vault.address, 100000000000000000000n], { account: user1.account });
  await vault.write.depositFunds([100000000000000000000n], { account: user1.account });
  await vault.write.pause([], { account: owner.account });

  await vault.write.withdraw([owner.account.address, 50000000000000000000n], { account: owner.account });
  const balance = await vault.read.getBalance();
  assert.equal(balance, 50000000000000000000n);
});

test("should return correct vault balance", async () => {
  const balance1 = await vault.read.getBalance();
  assert.equal(balance1, 0n);

  await rewardToken.write.approve([vault.address, 100000000000000000000n], { account: user1.account });
  await vault.write.depositFunds([100000000000000000000n], { account: user1.account });

  const balance2 = await vault.read.getBalance();
  assert.equal(balance2, 100000000000000000000n);
});