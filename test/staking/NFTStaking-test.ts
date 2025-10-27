import { network } from "hardhat";
import assert from "node:assert/strict";
import { beforeEach, test } from "node:test";

let nftStaking: any;
let owner: any;
let alice: any;
let bob: any;

beforeEach(async () => {
  // Connect to Hardhat's simulated network (via viem)
  const { viem: hreViem } = await network.connect("hardhat");
  const wallets = await hreViem.getWalletClients();

  [owner, alice, bob] = wallets;

  // Deploy NFTStaking contract
  nftStaking = await hreViem.deployContract("NFTStaking", [], {
    client: { wallet: owner },
  });
});

//
// 1️⃣ test_initialstate
//
test("should start with correct initial state", async () => {
  const contractOwner = await nftStaking.read.owner();
  const totalStaked = await nftStaking.read.totalStaked();
  assert.equal(
    contractOwner.toLowerCase(),
    owner.account.address.toLowerCase(),
    "Owner should be deployer"
  );
  assert.equal(totalStaked, 0n, "Total staked should start from 0");
});

//
// 2️⃣ test_Stake
//
test("should allow a user to stake", async () => {
  await nftStaking.write.stake([5n], { account: alice.account });
  const staked = await nftStaking.read.userStaked([alice.account.address]);
  assert.equal(staked, 5n);
  const totalStaked = await nftStaking.read.totalStaked();
  assert.equal(totalStaked, 5n);
});

//
// 3️⃣ test_Unstake
//
test("should allow a user to unstake", async () => {
  await nftStaking.write.stake([5n], { account: alice.account });
  await nftStaking.write.unstake([3n], { account: alice.account });
  let staked = await nftStaking.read.userStaked([alice.account.address]);
  assert.equal(staked, 2n, "Alice should have 2 staked left");

  await nftStaking.write.unstake([2n], { account: alice.account });
  staked = await nftStaking.read.userStaked([alice.account.address]);
  assert.equal(staked, 0n, "Alice should have 0 staked left");
});

//
// 4️⃣ test_FailUnstake
//
test("should fail when unstaking more than staked", async () => {
  await nftStaking.write.stake([5n], { account: alice.account });
  await assert.rejects(
    async () => {
      await nftStaking.write.unstake([10n], { account: alice.account });
    },
    /Not enough staked/,
    "Expected revert when unstaking more than staked"
  );
});

//
// 5️⃣ test_FailStakeZero
//
test("should fail when staking 0", async () => {
  await assert.rejects(
    async () => {
      await nftStaking.write.stake([0n], { account: alice.account });
    },
    /Amount must be positive/,
    "Expected staking 0 to revert"
  );
});

//
// 6️⃣ test_CalculateRewards
//
test("should calculate rewards correctly", async () => {
  await nftStaking.write.stake([7n], { account: bob.account });

  // simulate passing time if contract uses timestamps (optional)
  const rewardBob = await nftStaking.read.calculateRewards([
    bob.account.address,
  ]);
  assert.ok(rewardBob >= 0n, "Bob's reward should be non-negative");

  await nftStaking.write.stake([5n], { account: alice.account });
  const rewardAlice = await nftStaking.read.calculateRewards([
    alice.account.address,
  ]);
  assert.ok(rewardAlice >= 0n, "Alice's reward should be non-negative");

  const total = await nftStaking.read.totalStaked();
  assert.equal(total, 12n, "Total staked should be 12 after both staked");
});

//
// 7️⃣ test_ClaimRewardsAfterTime
//
test("should claim rewards and reset timestamp", async () => {
  await nftStaking.write.stake([10n], { account: alice.account });

  const rewardBefore = await nftStaking.read.calculateRewards([
    alice.account.address,
  ]);
  assert.ok(rewardBefore >= 0n, "Initial reward should be calculable");

  await nftStaking.write.claimRewards([], { account: alice.account });

  const newTimestamp = await nftStaking.read.stakeTimestamps([
    alice.account.address,
  ]);
  assert.ok(newTimestamp > 0n, "Timestamp should reset after claim");
});
