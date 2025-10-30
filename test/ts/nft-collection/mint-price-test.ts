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

test("should allow owner to set mint price", async () => {
  const newPrice = 100000000000000000n;
  await myNFT.write.setMintPrice([newPrice], { account: owner.account });
  const mintPrice = await myNFT.read.mintPrice();
  assert.equal(mintPrice, newPrice, "Mint price should be updated");
});

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