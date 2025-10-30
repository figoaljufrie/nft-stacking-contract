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

test("should start with correct initial state", async () => {
  const contractOwner = await vault.read.owner();
  const tokenAddress = await vault.read.rewardToken();
  const paused = await vault.read.paused();
  const balance = await vault.read.getBalance();

  assert.equal(contractOwner.toLowerCase(), owner.account.address.toLowerCase());
  assert.equal(tokenAddress.toLowerCase(), rewardToken.address.toLowerCase());
  assert.equal(paused, false);
  assert.equal(balance, 0n);
});

test("should return correct version", async () => {
  const version = await vault.read.version();
  assert.equal(version, "1.0.0");
});