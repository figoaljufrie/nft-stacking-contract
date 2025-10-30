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

test("should allow NFT owner to burn", async () => {
  // Mint to user1
  await myNFT.write.mint([user1.account.address, "ipfs://metadata1"], {
    account: owner.account,
  });

  // User1 burns token
  await myNFT.write.burn([1n], { account: user1.account });

  const totalSupply = await myNFT.read.totalSupply();
  const balance = await myNFT.read.balanceOf([user1.account.address]);

  assert.equal(totalSupply, 0n, "Total supply should be 0 after burn");
  assert.equal(balance, 0n, "User balance should be 0 after burn");
});