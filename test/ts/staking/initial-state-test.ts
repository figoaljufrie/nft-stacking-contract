import assert from "node:assert";
import { test, beforeEach } from "node:test";
import { deployContract, REWARD_RATE } from "./fixtures";

let stakingManager: any;
let rewardToken: any;
let mockNFT: any;
let owner: any;

beforeEach(async () => {
  ({ stakingManager, rewardToken, mockNFT, owner } = await deployContract());
});

test("should start with correct initial state", async () => {
  const nftCollection = await stakingManager.read.nftCollection();
  const rewardTokenAddr = await stakingManager.read.rewardToken();
  const rewardRate = await stakingManager.read.rewardRate();
  const contractOwner = await stakingManager.read.owner();
  const paused = await stakingManager.read.paused();

  assert.equal(nftCollection.toLowerCase(), mockNFT.address.toLowerCase());
  assert.equal(
    rewardTokenAddr.toLowerCase(),
    rewardToken.address.toLowerCase()
  );
  assert.equal(rewardRate, REWARD_RATE);
  assert.equal(
    contractOwner.toLowerCase(),
    owner.account.address.toLowerCase()
  );
  assert.equal(paused, false);
});

test("should return correct version", async () => {
  const version = await stakingManager.read.version();
  assert.equal(version, "1.0.0");
});
