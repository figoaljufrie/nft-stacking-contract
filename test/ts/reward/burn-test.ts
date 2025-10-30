import { beforeEach, test } from "node:test";
import assert from "node:assert/strict";
import { network } from "hardhat";
import { deployContract } from "./fixtures";

let rewardToken: any;
let owner: any;
let user1: any;

beforeEach(async () => {
  ({ rewardToken, owner, user1 } = await deployContract());
});

test("should allow users to burn their tokens", async () => {
  await rewardToken.write.transfer(
    [user1.account.address, 1000000000000000000n],
    {
      account: owner.account,
    }
  );

  const balanceBefore = await rewardToken.read.balanceOf([
    user1.account.address,
  ]);
  const totalSupplyBefore = await rewardToken.read.totalSupply();

  await rewardToken.write.burn([500000000000000000n], {
    account: user1.account,
  });

  const balanceAfter = await rewardToken.read.balanceOf([
    user1.account.address,
  ]);
  const totalSupplyAfter = await rewardToken.read.totalSupply();

  assert.equal(balanceAfter, balanceBefore - 500000000000000000n);
  assert.equal(totalSupplyAfter, totalSupplyBefore - 500000000000000000n);
});

test("should return correct version", async () => {
  const version = await rewardToken.read.version();
  assert.equal(version, "1.0.0");
});
