import { beforeEach, test } from "node:test";
import assert from "node:assert";
import network from "hardhat";
import { deployContract } from "./fixtures";

let rewardToken: any;
let owner: any;

beforeEach(async () => {
  ({ rewardToken, owner } = await deployContract());
});

test("should start with correct initial state", async () => {
  const name = await rewardToken.read.name();
  const symbol = await rewardToken.read.symbol();
  const contractOwner = await rewardToken.read.owner();
  const totalSupply = await rewardToken.read.totalSupply();
  const maxSupply = await rewardToken.read.MAX_SUPPLY();
  const paused = await rewardToken.read.paused();

  assert.equal(name, "Reward Token");
  assert.equal(symbol, "RWT");
  assert.equal(
    contractOwner.toLowerCase(),
    owner.account.address.toLowerCase()
  );
  assert.equal(totalSupply, 1000000000000000000000000n);
  assert.equal(maxSupply, 10000000000000000000000000n);
  assert.equal(paused, false);
});

test("should mint initial tokens to owner", async () => {
  const ownerBalance = await rewardToken.read.balanceOf([
    owner.account.address,
  ]);
  assert.equal(ownerBalance, 1000000000000000000000000n);
});
