import { beforeEach, test } from "node:test";
import assert from "node:assert/strict";
import { deployContract } from "./fixtures";

let myNFT: any;
let owner: any;
let user1: any;

beforeEach(async () => {
  ({ myNFT, owner, user1 } = await deployContract());
});

test("should allow owner to set base URI", async () => {
  await myNFT.write.setBaseURI(["https://api.example.com/"], {
    account: owner.account,
  });

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