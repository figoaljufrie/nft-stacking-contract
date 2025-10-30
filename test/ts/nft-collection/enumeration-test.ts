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

test("should enumerate tokens by index", async () => {
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

test("should enumerate tokens of owner by index", async () => {
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