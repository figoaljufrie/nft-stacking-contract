import { beforeEach, test } from "node:test";
import assert from "node:assert";
import { deployContract } from "./fixtures";

let myNFT: any;
let owner: any;
let user1: any;
let user2: any;

beforeEach(async () => {
  ({ myNFT, owner, user1, user2 } = await deployContract());
});

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
