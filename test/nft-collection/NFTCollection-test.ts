import { network } from "hardhat";
import assert from "node:assert/strict";
import { beforeEach, test } from "node:test";

let myNFT: any;
let owner: any;
let user1: any;
let user2: any;

beforeEach(async () => {
  // Connect to Hardhat's simulated network
  const { viem: hreViem } = await network.connect("hardhat");
  const wallets = await hreViem.getWalletClients();

  [owner, user1, user2] = wallets;

  // Deploy MyNFT contract with owner as initial owner
  myNFT = await hreViem.deployContract("MyNFT", [owner.account.address], {
    client: { wallet: owner },
  });
});

// Test initial state
test("should start with correct initial state", async () => {
  const contractOwner = await myNFT.read.owner();
  const totalSupply = await myNFT.read.totalSupply();
  const mintPrice = await myNFT.read.mintPrice();
  const name = await myNFT.read.name();
  const symbol = await myNFT.read.symbol();

  assert.equal(
    contractOwner.toLowerCase(),
    owner.account.address.toLowerCase(),
    "Owner should be deployer"
  );
  assert.equal(totalSupply, 0n, "Total supply should start at 0");
  assert.equal(mintPrice, 0n, "Mint price should start at 0");
  assert.equal(name, "MyNFT");
  assert.equal(symbol, "MNFT");
});

// Test owner can mint
test("should allow owner to mint NFT", async () => {
  // Owner mints to user1
  await myNFT.write.mint([user1.account.address, "ipfs://metadata1"], {
    account: owner.account,
  });

  const ownerOf = await myNFT.read.ownerOf([1n]);
  const totalSupply = await myNFT.read.totalSupply();
  const tokenURI = await myNFT.read.tokenURI([1n]);

  assert.equal(
    ownerOf.toLowerCase(),
    user1.account.address.toLowerCase(),
    "Token should belong to user1"
  );
  assert.equal(totalSupply, 1n, "Total supply should be 1");
  assert.equal(tokenURI, "ipfs://metadata1", "Token URI should match");
});

// Test non-owner cannot mint
test("should fail when non-owner tries to mint", async () => {
  let errorCaught = null;

  try {
    await myNFT.write.mint([user1.account.address, "ipfs://metadata1"], {
      account: user1.account,
    });
  } catch (err: any) {
    errorCaught = err;
  }

  assert.ok(errorCaught, "Expected a revert but no error was thrown");

  // Extract the reason as best we can
  const reason =
    errorCaught?.shortMessage ||
    errorCaught?.details ||
    errorCaught?.message ||
    errorCaught?.cause?.message ||
    errorCaught?.data?.error?.message ||
    "";

  // Normalize text for loose match
  const normalized = reason.toLowerCase();

  assert.ok(
    normalized.includes("ownable") ||
      normalized.includes("caller is not the owner") ||
      normalized.includes("revert") ||
      normalized.includes("unknown rpc error"),
    `Expected revert for non-owner, but got: ${reason}`
  );
});

// Test set mint price
test("should allow owner to set mint price", async () => {
  const newPrice = 100000000000000000n; // 0.1 ETH

  await myNFT.write.setMintPrice([newPrice], {
    account: owner.account,
  });

  const mintPrice = await myNFT.read.mintPrice();
  assert.equal(mintPrice, newPrice, "Mint price should be updated");
});

// Test non-owner cannot set mint price
test("should fail when non-owner tries to set mint price", async () => {
  let errorCaught = null;

  try {
    await myNFT.write.setMintPrice([100000000000000000n], {
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
    `Expected revert for non-owner setMintPrice, but got: ${reason}`
  );
});

// Test public mint with correct payment
test("should allow public mint with correct payment", async () => {
  // Set mint price to 0.1 ETH
  await myNFT.write.setMintPrice([100000000000000000n], {
    account: owner.account,
  });

  // User1 mints
  await myNFT.write.mintPublic(["ipfs://metadata1"], {
    account: user1.account,
    value: 100000000000000000n,
  });

  const ownerOf = await myNFT.read.ownerOf([1n]);
  const totalSupply = await myNFT.read.totalSupply();

  assert.equal(
    ownerOf.toLowerCase(),
    user1.account.address.toLowerCase(),
    "Token should belong to user1"
  );
  assert.equal(totalSupply, 1n, "Total supply should be 1");
});

// Test public mint with insufficient payment
test("should fail when public mint with insufficient payment", async () => {
  await myNFT.write.setMintPrice([100000000000000000n], {
    account: owner.account,
  });

  await assert.rejects(
    async () => {
      await myNFT.write.mintPublic(["ipfs://metadata1"], {
        account: user1.account,
        value: 50000000000000000n, // Only 0.05 ETH
      });
    },
    /Insufficient funds to mint/,
    "Expected revert with insufficient payment"
  );
});

// Test set base URI
test("should allow owner to set base URI", async () => {
  await myNFT.write.setBaseURI(["https://api.example.com/"], {
    account: owner.account,
  });

  // Mint a token
  await myNFT.write.mint([user1.account.address, "1"], {
    account: owner.account,
  });

  const tokenURI = await myNFT.read.tokenURI([1n]);
  assert.equal(
    tokenURI,
    "https://api.example.com/1",
    "Token URI should be baseURI + tokenURI"
  );
});

// Test withdraw funds
test("should allow owner to withdraw funds", async () => {
  // Setup: public mint to accumulate funds
  await myNFT.write.setMintPrice([100000000000000000n], {
    account: owner.account,
  });

  await myNFT.write.mintPublic(["ipfs://metadata1"], {
    account: user1.account,
    value: 100000000000000000n,
  });

  // Get balances before withdrawal
  const { viem: hreViem } = await network.connect("hardhat");
  const publicClient = await hreViem.getPublicClient();

  const balanceBefore = await publicClient.getBalance({
    address: owner.account.address,
  });
  const contractBalanceBefore = await publicClient.getBalance({
    address: myNFT.address,
  });

  // Withdraw
  await myNFT.write.withdraw([], {
    account: owner.account,
  });

  const balanceAfter = await publicClient.getBalance({
    address: owner.account.address,
  });

  const netGain = balanceAfter - balanceBefore;

  // ✅ Owner’s gain should roughly equal the contract’s prior balance (minus gas)
  assert.ok(
    netGain + 10_000_000_000_000n >= contractBalanceBefore,
    `Expected owner to gain approximately ${contractBalanceBefore}, but gained ${netGain}`
  );
});

// Test withdraw with no funds
test("should fail when withdrawing with no funds", async () => {
  await assert.rejects(
    async () => {
      await myNFT.write.withdraw([], {
        account: owner.account,
      });
    },
    /No funds to withdraw/,
    "Expected revert when no funds to withdraw"
  );
});

// Test non-owner cannot withdraw
test("should fail when non-owner tries to withdraw", async () => {
  let errorCaught = null;

  try {
    await myNFT.write.withdraw([], {
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

// Test NFT transfer
test("should allow NFT transfer", async () => {
  // Mint to user1
  await myNFT.write.mint([user1.account.address, "ipfs://metadata1"], {
    account: owner.account,
  });

  // User1 transfers to user2
  await myNFT.write.transferFrom(
    [user1.account.address, user2.account.address, 1n],
    {
      account: user1.account,
    }
  );

  const newOwner = await myNFT.read.ownerOf([1n]);
  assert.equal(
    newOwner.toLowerCase(),
    user2.account.address.toLowerCase(),
    "Token should now belong to user2"
  );
});

// Test NFT burn
test("should allow NFT owner to burn", async () => {
  // Mint to user1
  await myNFT.write.mint([user1.account.address, "ipfs://metadata1"], {
    account: owner.account,
  });

  // User1 burns token
  await myNFT.write.burn([1n], {
    account: user1.account,
  });

  const totalSupply = await myNFT.read.totalSupply();
  const balance = await myNFT.read.balanceOf([user1.account.address]);

  assert.equal(totalSupply, 0n, "Total supply should be 0 after burn");
  assert.equal(balance, 0n, "User balance should be 0 after burn");
});

// Test enumeration - tokenByIndex
test("should enumerate tokens by index", async () => {
  // Mint 3 tokens
  await myNFT.write.mint([user1.account.address, "ipfs://metadata1"], {
    account: owner.account,
  });
  await myNFT.write.mint([user1.account.address, "ipfs://metadata2"], {
    account: owner.account,
  });
  await myNFT.write.mint([user2.account.address, "ipfs://metadata3"], {
    account: owner.account,
  });

  const token0 = await myNFT.read.tokenByIndex([0n]);
  const token1 = await myNFT.read.tokenByIndex([1n]);
  const token2 = await myNFT.read.tokenByIndex([2n]);

  assert.equal(token0, 1n);
  assert.equal(token1, 2n);
  assert.equal(token2, 3n);
});

// Test enumeration - tokenOfOwnerByIndex
test("should enumerate tokens of owner by index", async () => {
  // Mint 2 tokens to user1, 1 to user2
  await myNFT.write.mint([user1.account.address, "ipfs://metadata1"], {
    account: owner.account,
  });
  await myNFT.write.mint([user1.account.address, "ipfs://metadata2"], {
    account: owner.account,
  });
  await myNFT.write.mint([user2.account.address, "ipfs://metadata3"], {
    account: owner.account,
  });

  const user1Token0 = await myNFT.read.tokenOfOwnerByIndex([
    user1.account.address,
    0n,
  ]);
  const user1Token1 = await myNFT.read.tokenOfOwnerByIndex([
    user1.account.address,
    1n,
  ]);
  const user2Token0 = await myNFT.read.tokenOfOwnerByIndex([
    user2.account.address,
    0n,
  ]);

  assert.equal(user1Token0, 1n);
  assert.equal(user1Token1, 2n);
  assert.equal(user2Token0, 3n);
});

// Test multiple mints and balance tracking
test("should track balances correctly across multiple mints", async () => {
  await myNFT.write.mint([user1.account.address, "ipfs://metadata1"], {
    account: owner.account,
  });
  await myNFT.write.mint([user1.account.address, "ipfs://metadata2"], {
    account: owner.account,
  });
  await myNFT.write.mint([user2.account.address, "ipfs://metadata3"], {
    account: owner.account,
  });

  const balance1 = await myNFT.read.balanceOf([user1.account.address]);
  const balance2 = await myNFT.read.balanceOf([user2.account.address]);
  const totalSupply = await myNFT.read.totalSupply();

  assert.equal(balance1, 2n, "User1 should have 2 NFTs");
  assert.equal(balance2, 1n, "User2 should have 1 NFT");
  assert.equal(totalSupply, 3n, "Total supply should be 3");
});
