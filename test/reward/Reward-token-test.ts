import { network } from "hardhat";
import assert from "node:assert/strict";
import { beforeEach, test } from "node:test";

let rewardToken: any;
let owner: any;
let stakingManager: any;
let user1: any;

beforeEach(async () => {
  // Connect to Hardhat's simulated network
  const { viem: hreViem } = await network.connect("hardhat");
  const wallets = await hreViem.getWalletClients();

  [owner, stakingManager, user1] = wallets;

  // Deploy RewardTokenUpgradeable
  rewardToken = await hreViem.deployContract("RewardTokenUpgradeable", [], {
    client: { wallet: owner },
  });

  // Initialize the upgradeable contract
  await rewardToken.write.initialize(
    ["Reward Token", "RWT", owner.account.address],
    {
      account: owner.account,
    }
  );
});

// Test initial state
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
  // Owner gets 1M tokens initially
  assert.equal(totalSupply, 1000000000000000000000000n); // 1M * 10^18
  assert.equal(maxSupply, 10000000000000000000000000n); // 10M * 10^18
  assert.equal(paused, false);
});

// Test owner receives initial mint
test("should mint initial tokens to owner", async () => {
  const ownerBalance = await rewardToken.read.balanceOf([
    owner.account.address,
  ]);
  assert.equal(ownerBalance, 1000000000000000000000000n); // 1M tokens
});

// Test set staking manager
test("should allow owner to set staking manager", async () => {
  await rewardToken.write.setStakingManager([stakingManager.account.address], {
    account: owner.account,
  });

  const manager = await rewardToken.read.stakingManager();
  assert.equal(
    manager.toLowerCase(),
    stakingManager.account.address.toLowerCase()
  );
});

// Test non-owner cannot set staking manager
test("should fail when non-owner tries to set staking manager", async () => {
  let errorCaught = null;

  try {
    await rewardToken.write.setStakingManager(
      [stakingManager.account.address],
      {
        account: user1.account,
      }
    );
  } catch (err: any) {
    errorCaught = err;
  }

  assert.ok(errorCaught, "Expected a revert but no error was thrown");

  const reason =
    errorCaught?.shortMessage ||
    errorCaught?.details ||
    errorCaught?.message ||
    errorCaught?.cause?.message ||
    errorCaught?.data?.error?.message ||
    "";

  const normalized = reason.toLowerCase();

  assert.ok(
    normalized.includes("ownable") ||
      normalized.includes("caller is not the owner") ||
      normalized.includes("revert") ||
      normalized.includes("unknown rpc error"),
    `Expected revert for non-owner setStakingManager, but got: ${reason}`
  );
});


// Test cannot set zero address as staking manager
test("should fail when setting zero address as staking manager", async () => {
  await assert.rejects(
    async () => {
      await rewardToken.write.setStakingManager(
        ["0x0000000000000000000000000000000000000000"],
        {
          account: owner.account,
        }
      );
    },
    /Invalid manager address/,
    "Expected revert when setting zero address"
  );
});

// Test staking manager can mint
test("should allow staking manager to mint tokens", async () => {
  // Set staking manager
  await rewardToken.write.setStakingManager([stakingManager.account.address], {
    account: owner.account,
  });

  // Staking manager mints to user1
  await rewardToken.write.mint([user1.account.address, 1000000000000000000n], {
    account: stakingManager.account,
  });

  const user1Balance = await rewardToken.read.balanceOf([
    user1.account.address,
  ]);
  assert.equal(user1Balance, 1000000000000000000n); // 1 token
});

// Test non-staking-manager cannot mint
test("should fail when non-staking-manager tries to mint", async () => {
  await assert.rejects(
    async () => {
      await rewardToken.write.mint(
        [user1.account.address, 1000000000000000000n],
        {
          account: user1.account,
        }
      );
    },
    /Not Authorized/,
    "Expected revert when non-staking-manager tries to mint"
  );
});

// Test cannot mint beyond max supply
test("should fail when minting beyond max supply", async () => {
  await rewardToken.write.setStakingManager([stakingManager.account.address], {
    account: owner.account,
  });

  // Try to mint more than max supply (10M total, 1M already minted)
  const excessAmount = 9000001000000000000000000n; // 9M + 1 tokens

  await assert.rejects(
    async () => {
      await rewardToken.write.mint([user1.account.address, excessAmount], {
        account: stakingManager.account,
      });
    },
    /Exceeds max supply/,
    "Expected revert when exceeding max supply"
  );
});

// Test pause functionality
test("should allow owner to pause contract", async () => {
  await rewardToken.write.pause([], {
    account: owner.account,
  });

  const paused = await rewardToken.read.paused();
  assert.equal(paused, true);
});

// Test unpause functionality
test("should allow owner to unpause contract", async () => {
  await rewardToken.write.pause([], {
    account: owner.account,
  });

  await rewardToken.write.unpause([], {
    account: owner.account,
  });

  const paused = await rewardToken.read.paused();
  assert.equal(paused, false);
});

// Test non-owner cannot pause
test("should fail when non-owner tries to pause", async () => {
  let errorCaught = null;

  try {
    await rewardToken.write.pause([], {
      account: user1.account,
    });
  } catch (err: any) {
    errorCaught = err;
  }

  assert.ok(errorCaught, "Expected a revert but no error was thrown");

  const reason =
    errorCaught?.shortMessage ||
    errorCaught?.details ||
    errorCaught?.message ||
    errorCaught?.cause?.message ||
    errorCaught?.data?.error?.message ||
    "";

  const normalized = reason.toLowerCase();

  assert.ok(
    normalized.includes("ownable") ||
      normalized.includes("caller is not the owner") ||
      normalized.includes("revert") ||
      normalized.includes("unknown rpc error"),
    `Expected revert for non-owner pause, but got: ${reason}`
  );
});

// Test transfers blocked when paused
test("should block transfers when paused", async () => {
  await rewardToken.write.transfer(
    [user1.account.address, 1000000000000000000n],
    { account: owner.account }
  );

  await rewardToken.write.pause([], {
    account: owner.account,
  });

  let errorCaught = null;

  try {
    await rewardToken.write.transfer(
      [owner.account.address, 500000000000000000n],
      {
        account: user1.account,
      }
    );
  } catch (err: any) {
    errorCaught = err;
  }

  assert.ok(errorCaught, "Expected a revert but no error was thrown");

  const reason =
    errorCaught?.shortMessage ||
    errorCaught?.details ||
    errorCaught?.message ||
    errorCaught?.cause?.message ||
    errorCaught?.data?.error?.message ||
    "";

  const normalized = reason.toLowerCase();

  assert.ok(
    normalized.includes("paused") ||
      normalized.includes("pausable") ||
      normalized.includes("revert") ||
      normalized.includes("unknown rpc error"),
    `Expected revert for paused transfer, but got: ${reason}`
  );
});

// Test minting blocked when paused
test("should block minting when paused", async () => {
  await rewardToken.write.setStakingManager([stakingManager.account.address], {
    account: owner.account,
  });

  await rewardToken.write.pause([], {
    account: owner.account,
  });

  let errorCaught = null;

  try {
    await rewardToken.write.mint(
      [user1.account.address, 1000000000000000000n],
      { account: stakingManager.account }
    );
  } catch (err: any) {
    errorCaught = err;
  }

  assert.ok(errorCaught, "Expected a revert but no error was thrown");

  const reason =
    errorCaught?.shortMessage ||
    errorCaught?.details ||
    errorCaught?.message ||
    errorCaught?.cause?.message ||
    errorCaught?.data?.error?.message ||
    "";

  const normalized = reason.toLowerCase();

  assert.ok(
    normalized.includes("paused") ||
      normalized.includes("pausable") ||
      normalized.includes("revert") ||
      normalized.includes("unknown rpc error"),
    `Expected revert for paused minting, but got: ${reason}`
  );
});

// Test token burn
test("should allow users to burn their tokens", async () => {
  // Transfer some tokens to user1
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

  // User1 burns tokens
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

// Test version
test("should return correct version", async () => {
  const version = await rewardToken.read.version();
  assert.equal(version, "1.0.0");
});

// Test transfer
test("should allow token transfers", async () => {
  const transferAmount = 1000000000000000000n;

  await rewardToken.write.transfer([user1.account.address, transferAmount], {
    account: owner.account,
  });

  const user1Balance = await rewardToken.read.balanceOf([
    user1.account.address,
  ]);
  assert.equal(user1Balance, transferAmount);
});

// Test approve and transferFrom
test("should allow approve and transferFrom", async () => {
  const approveAmount = 1000000000000000000n;
  const transferAmount = 500000000000000000n;

  // Owner approves user1 to spend tokens
  await rewardToken.write.approve([user1.account.address, approveAmount], {
    account: owner.account,
  });

  const allowance = await rewardToken.read.allowance([
    owner.account.address,
    user1.account.address,
  ]);
  assert.equal(allowance, approveAmount);

  // User1 transfers from owner to themselves
  await rewardToken.write.transferFrom(
    [owner.account.address, user1.account.address, transferAmount],
    {
      account: user1.account,
    }
  );

  const user1Balance = await rewardToken.read.balanceOf([
    user1.account.address,
  ]);
  assert.equal(user1Balance, transferAmount);
});

// Test decimals
test("should have 18 decimals", async () => {
  const decimals = await rewardToken.read.decimals();
  assert.equal(decimals, 18);
});