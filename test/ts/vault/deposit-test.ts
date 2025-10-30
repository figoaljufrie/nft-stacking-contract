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

test("should allow users to deposit funds", async () => {
  const depositAmount = 100000000000000000000n;
  await rewardToken.write.approve([vault.address, depositAmount], { account: user1.account });
  await vault.write.depositFunds([depositAmount], { account: user1.account });

  const balance = await vault.read.getBalance();
  const user1Balance = await rewardToken.read.balanceOf([user1.account.address]);

  assert.equal(balance, depositAmount);
  assert.equal(user1Balance, 900000000000000000000n);
});

test("should handle multiple deposits", async () => {
  const amount1 = 200000000000000000000n;
  const amount2 = 300000000000000000000n;

  await rewardToken.write.approve([vault.address, amount1], { account: user1.account });
  await vault.write.depositFunds([amount1], { account: user1.account });

  await rewardToken.write.approve([vault.address, amount2], { account: user2.account });
  await vault.write.depositFunds([amount2], { account: user2.account });

  const balance = await vault.read.getBalance();
  assert.equal(balance, amount1 + amount2);
});

test("should fail when depositing zero amount", async () => {
  await assert.rejects(
    async () => { await vault.write.depositFunds([0n], { account: user1.account }); },
    /Invalid amount/
  );
});

test("should fail when depositing without approval", async () => {
  let errorCaught: any = null;

  try {
    await vault.write.depositFunds([100000000000000000000n], { account: user1.account });
  } catch (err: any) {
    errorCaught = err;
  }

  assert.ok(errorCaught);
  const reason =
    errorCaught?.shortMessage || errorCaught?.details || errorCaught?.message ||
    errorCaught?.cause?.message || errorCaught?.data?.error?.message || "";
  const normalized = reason.toLowerCase();
  assert.ok(normalized.includes("transfer failed") || normalized.includes("revert") || normalized.includes("execution reverted") || normalized.includes("unknown rpc error"));
});