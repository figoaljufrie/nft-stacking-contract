import { network } from "hardhat";
import assert from "node:assert/strict";
import { beforeEach, test } from "node:test";

let myNFT: any;
let owner: any;
let alice: any;
let bob: any;

//every test starts fresh:
//connects to hardhat local blockchain, implement 3 dummy wallets, and deploys nft contract (owner as deployer).
beforeEach(async () => {
  //connect to the simulated network (via viem);
  const { viem: hreViem } = await network.connect("hardhat");
  //create 3 dummy wallets:
  const wallets = await hreViem.getWalletClients();
  [owner, alice, bob] = wallets;

  myNFT = await hreViem.deployContract("MyNFT", [owner.account.address], {
    //Owner: deployer
    client: { wallet: owner },
  });
});
//reads the correct metadata for each nft:
test("should have correct name and symbol", async () => {
  const name = await myNFT.read.name();
  const symbol = await myNFT.read.symbol();

  assert.equal(name, "MyNFT", "Name should be myNFT");
  assert.equal(symbol, "MNFT", "Symbol should be MNFT");
});

//minting test as the owner: Other cannot.
test("should allow only owner to mint", async () => {
  await myNFT.write.mint([alice.account.address, "ipfs://token-1.json"], {
    account: owner.account,
  });

  const uri = await myNFT.read.tokenURI([1]);
  assert.equal(uri, "ipfs://token-1.json", "Token URI should match");
});

//If other people want to mint, it should revert(cannot). 
test("should revert if non-owner tries to mint", async () => {
  await assert.rejects(
    async () => {
      await myNFT.write.mint(
        [alice.account.address, "ipfs://unauthorized.json"],
        { account: alice.account }
      );
    },
    /OwnableUnauthorizedAccount/,
    "Non-owner minting should revert"
  );
});

//this is to test whether the tokenId increment correctly after each mint.
test("should increment tokenId correctly", async () => {
  await myNFT.write.mint([alice.account.address, "ipfs://1.json"], {
    account: owner.account,
  });
  await myNFT.write.mint([bob.account.address, "ipfs://2.json"], {
    account: owner.account,
  });

  const uri1 = await myNFT.read.tokenURI([1]);
  const uri2 = await myNFT.read.tokenURI([2]);

  assert.equal(uri1, "ipfs://1.json", "Token 1 URI Mismatch");
  assert.equal(uri2, "ipfs://2.json", "Token 2 URI Mismatch");
});

//update balance after minting.
test("should update balances correctly after mint", async () => {
  await myNFT.write.mint([alice.account.address, "ipfs://a.json"], {
    account: owner.account,
  });
  await myNFT.write.mint([bob.account.address, "ipfs://b.json"], {
    account: owner.account,
  });

  const aliceBalance = await myNFT.read.balanceOf([alice.account.address]);
  const bobBalance = await myNFT.read.balanceOf([bob.account.address]);

  assert.equal(aliceBalance, 1n, "Alice Should have 1 NFT");
  assert.equal(bobBalance, 1n, "Bob should have 1 NFT");
});
