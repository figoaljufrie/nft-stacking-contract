import { network } from "hardhat";
import assert from "node:assert/strict";
import { beforeEach, test } from "node:test";

let vault: any;
let rewardToken: any;
let owner: any;
let user1: any;
let user2: any;

beforeEach(async () => {
  // Connect to Hardhat's simulated network
  const { viem: hreViem } = await network.connect("hardhat");
  const wallets = await hreViem.getWalletClients();

  [owner, user1, user2] = wallets;

  // Deploy MockRewardToken
  rewardToken = await hreViem.deployContract("MockRewardToken", [], {
    client: { wallet: owner },
  });

  // Deploy TreasuryVault
  vault = await hreViem.deployContract("TreasuryVault", [], {
    client: { wallet: owner },
  });

  // Initialize vault
  await vault.write.initialize([rewardToken.address, owner.account.address], {
    account: owner.account,
  });

  // Mint tokens to users for testing
  await rewardToken.write.mint([user1.account.address, 1000000000000000000000n], {
    account: owner.account,
  });
  await rewardToken.write.mint([user2.account.address, 1000000000000000000000n], {
    account: owner.account,
  });
});

// Test initial state
test("should start with correct initial state", async () => {
  const contractOwner = await vault.read.owner();
  const tokenAddress = await vault.read.rewardToken();
  const paused = await vault.read.paused();
  const balance = await vault.read.getBalance();

  assert.equal(
    contractOwner.toLowerCase(),
    owner.account.address.toLowerCase()
  );
  assert.equal(tokenAddress.toLowerCase(), rewardToken.address.toLowerCase());
  assert.equal(paused, false);
  assert.equal(balance, 0n);
});

// Test deposit funds
test("should allow users to deposit funds", async () => {
  const depositAmount = 100000000000000000000n; // 100 tokens

  // User1 approves vault
  await rewardToken.write.approve([vault.address, depositAmount], {
    account: user1.account,
  });

  // User1 deposits
  await vault.write.depositFunds([depositAmount], {
    account: user1.account,
  });

  const balance = await vault.read.getBalance();
  const user1Balance = await rewardToken.read.balanceOf([
    user1.account.address,
  ]);

  assert.equal(balance, depositAmount);
  assert.equal(user1Balance, 900000000000000000000n); // 1000 - 100
});

// Test multiple deposits
test("should handle multiple deposits", async () => {
  const amount1 = 200000000000000000000n;
  const amount2 = 300000000000000000000n;

  // User1 deposits
  await rewardToken.write.approve([vault.address, amount1], {
    account: user1.account,
  });
  await vault.write.depositFunds([amount1], {
    account: user1.account,
  });

  // User2 deposits
  await rewardToken.write.approve([vault.address, amount2], {
    account: user2.account,
  });
  await vault.write.depositFunds([amount2], {
    account: user2.account,
  });

  const balance = await vault.read.getBalance();
  assert.equal(balance, amount1 + amount2);
});

// Test deposit zero amount fails
test("should fail when depositing zero amount", async () => {
  await assert.rejects(
    async () => {
      await vault.write.depositFunds([0n], {
        account: user1.account,
      });
    },
    /Invalid amount/,
    "Expected revert when depositing zero"
  );
});

// Test deposit without approval fails
test("should fail when depositing without approval", async () => {
  let errorCaught: any = null;

  try {
    await vault.write.depositFunds([100000000000000000000n], {
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
    normalized.includes("transfer failed") ||
      normalized.includes("revert") ||
      normalized.includes("execution reverted") ||
      normalized.includes("unknown rpc error"),
    `Expected revert for deposit without approval, but got: ${reason}`
  );
});

// Test owner withdraw
test("should allow owner to withdraw funds", async () => {
  const depositAmount = 100000000000000000000n;
  const withdrawAmount = 50000000000000000000n;

  // Setup: deposit funds
  await rewardToken.write.approve([vault.address, depositAmount], {
    account: user1.account,
  });
  await vault.write.depositFunds([depositAmount], {
    account: user1.account,
  });

  const ownerBalanceBefore = await rewardToken.read.balanceOf([
    owner.account.address,
  ]);

  // Owner withdraws
  await vault.write.withdraw([owner.account.address, withdrawAmount], {
    account: owner.account,
  });

  const ownerBalanceAfter = await rewardToken.read.balanceOf([
    owner.account.address,
  ]);
  const vaultBalance = await vault.read.getBalance();

  assert.equal(ownerBalanceAfter, ownerBalanceBefore + withdrawAmount);
  assert.equal(vaultBalance, depositAmount - withdrawAmount);
});

// Test non-owner cannot withdraw
test("should fail when non-owner tries to withdraw", async () => {
  let errorCaught: any = null;

  try {
    await vault.write.withdraw([user1.account.address, 50000000000000000000n], {
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
    `Expected revert for non-owner withdraw, but got: ${reason}`
  );
});

// Test withdraw with insufficient balance fails
test("should fail when withdrawing more than balance", async () => {
  await assert.rejects(
    async () => {
      await vault.write.withdraw(
        [owner.account.address, 100000000000000000000n],
        {
          account: owner.account,
        }
      );
    },
    /Insufficient balance/,
    "Expected revert when withdrawing more than balance"
  );
});

// Test withdraw zero amount fails
test("should fail when withdrawing zero amount", async () => {
  await assert.rejects(
    async () => {
      await vault.write.withdraw([owner.account.address, 0n], {
        account: owner.account,
      });
    },
    /Invalid amount/,
    "Expected revert when withdrawing zero"
  );
});

// Test withdraw to zero address fails
test("should fail when withdrawing to zero address", async () => {
  await assert.rejects(
    async () => {
      await vault.write.withdraw(
        ["0x0000000000000000000000000000000000000000", 100000000000000000000n],
        {
          account: owner.account,
        }
      );
    },
    /Invalid Recipient/,
    "Expected revert when withdrawing to zero address"
  );
});

// Test send reward
test("should allow owner to send rewards", async () => {
  const depositAmount = 100000000000000000000n;
  const rewardAmount = 30000000000000000000n;

  // Setup: deposit funds
  await rewardToken.write.approve([vault.address, depositAmount], {
    account: user1.account,
  });
  await vault.write.depositFunds([depositAmount], {
    account: user1.account,
  });

  const user2BalanceBefore = await rewardToken.read.balanceOf([
    user2.account.address,
  ]);

  // Owner sends reward
  await vault.write.sendReward([user2.account.address, rewardAmount], {
    account: owner.account,
  });

  const user2BalanceAfter = await rewardToken.read.balanceOf([
    user2.account.address,
  ]);
  const vaultBalance = await vault.read.getBalance();

  assert.equal(user2BalanceAfter, user2BalanceBefore + rewardAmount);
  assert.equal(vaultBalance, depositAmount - rewardAmount);
});

// Test non-owner cannot send reward
test("should fail when non-owner tries to send reward", async () => {
  let errorCaught: any = null;

  try {
    await vault.write.sendReward([user2.account.address, 10000000000000000000n], {
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
    `Expected revert for non-owner sendReward, but got: ${reason}`
  );
});

// Test send reward with insufficient balance fails
test("should fail when sending reward exceeds balance", async () => {
  await assert.rejects(
    async () => {
      await vault.write.sendReward(
        [user2.account.address, 100000000000000000000n],
        {
          account: owner.account,
        }
      );
    },
    /Insufficient balance/,
    "Expected revert when sending reward exceeds balance"
  );
});

// Test send reward zero amount fails
test("should fail when sending zero reward", async () => {
  await assert.rejects(
    async () => {
      await vault.write.sendReward([user2.account.address, 0n], {
        account: owner.account,
      });
    },
    /invalid amount/,
    "Expected revert when sending zero reward"
  );
});

// Test send reward to zero address fails
test("should fail when sending reward to zero address", async () => {
  await assert.rejects(
    async () => {
      await vault.write.sendReward(
        ["0x0000000000000000000000000000000000000000", 10000000000000000000n],
        {
          account: owner.account,
        }
      );
    },
    /Invalid Recipient/,
    "Expected revert when sending reward to zero address"
  );
});

// Test pause
test("should allow owner to pause vault", async () => {
  await vault.write.pause([], {
    account: owner.account,
  });

  const paused = await vault.read.paused();
  assert.equal(paused, true);
});

// Test unpause
test("should allow owner to unpause vault", async () => {
  await vault.write.pause([], {
    account: owner.account,
  });

  await vault.write.unpause([], {
    account: owner.account,
  });

  const paused = await vault.read.paused();
  assert.equal(paused, false);
});

// Test non-owner cannot pause
test("should fail when non-owner tries to pause", async () => {
  let errorCaught: any = null;

  try {
    await vault.write.pause([], {
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

// Test deposit when paused fails
test("should fail when depositing while paused", async () => {
  await vault.write.pause([], {
    account: owner.account,
  });

  await rewardToken.write.approve([vault.address, 100000000000000000000n], {
    account: user1.account,
  });

  await assert.rejects(
    async () => {
      await vault.write.depositFunds([100000000000000000000n], {
        account: user1.account,
      });
    },
    /Vault is paused/,
    "Expected revert when depositing while paused"
  );
});

// Test send reward when paused fails
test("should fail when sending reward while paused", async () => {
  // Setup: deposit funds
  await rewardToken.write.approve([vault.address, 100000000000000000000n], {
    account: user1.account,
  });
  await vault.write.depositFunds([100000000000000000000n], {
    account: user1.account,
  });

  // Pause vault
  await vault.write.pause([], {
    account: owner.account,
  });

  await assert.rejects(
    async () => {
      await vault.write.sendReward([user2.account.address, 10000000000000000000n], {
        account: owner.account,
      });
    },
    /Vault is paused/,
    "Expected revert when sending reward while paused"
  );
});

// Test withdraw when paused (should succeed)
test("should allow owner to withdraw even when paused", async () => {
  // Setup: deposit funds
  await rewardToken.write.approve([vault.address, 100000000000000000000n], {
    account: user1.account,
  });
  await vault.write.depositFunds([100000000000000000000n], {
    account: user1.account,
  });

  // Pause vault
  await vault.write.pause([], {
    account: owner.account,
  });

  // Owner should still be able to withdraw (emergency access)
  await vault.write.withdraw([owner.account.address, 50000000000000000000n], {
    account: owner.account,
  });

  const balance = await vault.read.getBalance();
  assert.equal(balance, 50000000000000000000n);
});

// Test get balance
test("should return correct vault balance", async () => {
  const balance1 = await vault.read.getBalance();
  assert.equal(balance1, 0n);

  await rewardToken.write.approve([vault.address, 100000000000000000000n], {
    account: user1.account,
  });
  await vault.write.depositFunds([100000000000000000000n], {
    account: user1.account,
  });

  const balance2 = await vault.read.getBalance();
  assert.equal(balance2, 100000000000000000000n);
});

// Test version
test("should return correct version", async () => {
  const version = await vault.read.version();
  assert.equal(version, "1.0.0");
});