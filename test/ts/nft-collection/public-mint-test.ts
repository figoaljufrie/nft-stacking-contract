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

test("should allow public mint with correct payment", async () => {
  await myNFT.write.setMintPrice([100000000000000000n], {
    account: owner.account,
  });

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

test("should fail when public mint with insufficient payment", async () => {
  await myNFT.write.setMintPrice([100000000000000000n], {
    account: owner.account,
  });

  await assert.rejects(
    async () => {
      await myNFT.write.mintPublic(["ipfs://metadata1"], {
        account: user1.account,
        value: 50000000000000000n,
      });
    },
    /Insufficient funds to mint/,
    "Expected revert with insufficient payment"
  );
});