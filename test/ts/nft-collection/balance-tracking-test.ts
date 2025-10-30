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