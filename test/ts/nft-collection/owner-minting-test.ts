import { beforeEach, test } from "node:test";
import assert from "node:assert/strict";
import { deployContract } from "./fixtures";

let myNFT: any;
let owner: any;
let user1: any;
let user2: any;

beforeEach(async () => {
  ({ myNFT, owner, user1, user2 } = await deployContract());
});

test("should allow owner to mint NFT", async () => {
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
    `Expected revert for non-owner, but got: ${reason}`
  );
});