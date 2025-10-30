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

test("should allow owner to withdraw funds", async () => {
  const depositAmount = 100000000000000000000n;
  const withdrawAmount = 50000000000000000000n;

  await rewardToken.write.approve([vault.address, depositAmount], { account: user1.account });
  await vault.write.depositFunds([depositAmount], { account: user1.account });

  const ownerBalanceBefore = await rewardToken.read.balanceOf([owner.account.address]);
  await vault.write.withdraw([owner.account.address, withdrawAmount], { account: owner.account });

  const ownerBalanceAfter = await rewardToken.read.balanceOf([owner.account.address]);
  const vaultBalance = await vault.read.getBalance();

  assert.equal(ownerBalanceAfter, ownerBalanceBefore + withdrawAmount);
  assert.equal(vaultBalance, depositAmount - withdrawAmount);
});

test("should fail when non-owner tries to withdraw", async () => {
  let errorCaught: any = null;

  try {
    await vault.write.withdraw([user1.account.address, 50000000000000000000n], { account: user1.account });
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

test("should fail when withdrawing more than balance", async () => {
  await assert.rejects(
    async () => { await vault.write.withdraw([owner.account.address, 100000000000000000000n], { account: owner.account }); },
    /Insufficient balance/
  );
});

test("should fail when withdrawing zero amount", async () => {
  await assert.rejects(
    async () => { await vault.write.withdraw([owner.account.address, 0n], { account: owner.account }); },
    /Invalid amount/
  );
});

test("should fail when withdrawing to zero address", async () => {
  await assert.rejects(
    async () => { await vault.write.withdraw(["0x0000000000000000000000000000000000000000", 100000000000000000000n], { account: owner.account }); },
    /Invalid Recipient/
  );
});