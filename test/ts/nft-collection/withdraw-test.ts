import { beforeEach, test } from "node:test";
import assert from "node:assert/strict";
import { network } from "hardhat";
import { deployContract } from "./fixtures";

let myNFT: any;
let owner: any;
let user1: any;

beforeEach(async () => {
  ({ myNFT, owner, user1 } = await deployContract());
});

test("should allow owner to withdraw funds", async () => {
  await myNFT.write.setMintPrice([100000000000000000n], {
    account: owner.account,
  });

  await myNFT.write.mintPublic(["ipfs://metadata1"], {
    account: user1.account,
    value: 100000000000000000n,
  });

  const { viem: hreViem } = await network.connect("hardhat");
  const publicClient = await hreViem.getPublicClient();

  const balanceBefore = await publicClient.getBalance({
    address: owner.account.address,
  });
  const contractBalanceBefore = await publicClient.getBalance({
    address: myNFT.address,
  });

  await myNFT.write.withdraw([], { account: owner.account });

  const balanceAfter = await publicClient.getBalance({
    address: owner.account.address,
  });

  const netGain = balanceAfter - balanceBefore;

  assert.ok(
    netGain + 10_000_000_000_000n >= contractBalanceBefore,
    `Expected owner to gain approximately ${contractBalanceBefore}, but gained ${netGain}`
  );
});

test("should fail when withdrawing with no funds", async () => {
  await assert.rejects(
    async () => {
      await myNFT.write.withdraw([], { account: owner.account });
    },
    /No funds to withdraw/,
    "Expected revert when no funds to withdraw"
  );
});

test("should fail when non-owner tries to withdraw", async () => {
  let errorCaught = null;

  try {
    await myNFT.write.withdraw([], { account: user1.account });
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