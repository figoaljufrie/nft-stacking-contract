import assert from "node:assert/strict";
import { test, beforeEach } from "node:test";
import { deployContract } from "./fixtures";

let stakingManager: any;
let mockNFT: any;
let owner: any;
let user1: any;

beforeEach(async () => {
  ({ stakingManager, mockNFT, owner, user1 } = await deployContract());
});

test("should allow owner to pause staking", async () => {
  await stakingManager.write.setPaused([true], { account: owner.account });
  const paused = await stakingManager.read.paused();
  assert.equal(paused, true);
});

test("should fail when staking while paused", async () => {
  await stakingManager.write.setPaused([true], {
    account: owner.account,
  });

  await mockNFT.write.setApprovalForAll([stakingManager.address, true], {
    account: user1.account,
  });

  await assert.rejects(
    async () => {
      await stakingManager.write.stake([[0n]], {
        account: user1.account,
      });
    },
    /Contract is paused/,
    "Expected revert when staking while paused"
  );
});

test("should allow owner to unpause", async () => {
  await stakingManager.write.setPaused([true], { account: owner.account });
  await stakingManager.write.setPaused([false], { account: owner.account });
  const paused = await stakingManager.read.paused();
  assert.equal(paused, false);
});
