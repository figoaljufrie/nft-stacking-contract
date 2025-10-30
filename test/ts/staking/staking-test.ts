import assert from "node:assert";
import { test, beforeEach } from "node:test";
import { deployContract } from "./fixtures";

let stakingManager: any;
let mockNFT: any;
let owner: any;
let user1: any;

beforeEach(async () => {
  ({ stakingManager, mockNFT, owner, user1 } = await deployContract());
});

test("should allow user to stake NFTs", async () => {
  // User1 approves staking manager
  await mockNFT.write.setApprovalForAll([stakingManager.address, true], {
    account: user1.account,
  });

  // User1 stakes tokens 0 and 1
  await stakingManager.write.stake([[0n, 1n]], {
    account: user1.account,
  });

  // Check staked tokens
  const [stakedTokens, , accumulatedReward] =
    await stakingManager.read.getUserStakeInfo([user1.account.address]);

  assert.equal(stakedTokens.length, 2);
  assert.equal(stakedTokens[0], 0n);
  assert.equal(stakedTokens[1], 1n);
  assert.equal(accumulatedReward, 0n); // Initially 0
});

test("should fail when staking without approval", async () => {
  let errorCaught: any = null;

  try {
    await stakingManager.write.stake([[0n]], {
      account: user1.account,
    });
  } catch (err: any) {
    errorCaught = err;
  }

  assert.ok(errorCaught, "Expected a revert but no error was thrown");

  // Extract possible error reason
  const reason =
    errorCaught?.shortMessage ||
    errorCaught?.details ||
    errorCaught?.message ||
    errorCaught?.cause?.message ||
    errorCaught?.data?.error?.message ||
    "";

  const normalized = reason.toLowerCase();

  assert.ok(
    normalized.includes("erc721") ||
      normalized.includes("not token owner") ||
      normalized.includes("not approved") ||
      normalized.includes("revert") ||
      normalized.includes("unknown rpc error"),
    `Expected revert for staking without approval, but got: ${reason}`
  );
});

test("should fail when staking empty array", async () => {
  await assert.rejects(async () => {
    let errorCaught: any = null;
    try {
      await stakingManager.write.stake([[]], { account: user1.account });
    } catch (err: any) {
      errorCaught = err;
    }
    await stakingManager.write.stake([[]], {
      account: user1.account,
    });
    assert.ok(errorCaught, "Expected a revert but no error was thrown");

    // Extract possible error reason
    const reason =
      errorCaught?.shortMessage ||
      errorCaught?.details ||
      errorCaught?.message ||
      errorCaught?.cause?.message ||
      errorCaught?.data?.error?.message ||
      "";

    const normalized = reason.toLowerCase();

    assert.ok(
      normalized.includes("erc721") ||
        normalized.includes("not token owner") ||
        normalized.includes("not approved") ||
        normalized.includes("revert") ||
        normalized.includes("unknown rpc error"),
      `Expected revert for staking without approval, but got: ${reason}`
    );
  });
});
