import { expect } from "chai";
import hre from "hardhat";
import type { NFTStaking } from "../types/ethers-contracts/NFTStaking.js";

describe("NFTStaking Contract", function () {
  let nftStaking: NFTStaking;
  let owner: any;
  let alice: any;
  let bob: any;

  beforeEach(async () => {
    // Type assertion to access ethers
    const ethers = (hre as any).ethers;
    const [deployer, user1, user2] = await ethers.getSigners();

    owner = deployer;
    alice = user1;
    bob = user2;

    const NFTStakingFactory = await ethers.getContractFactory("NFTStaking");
    const contract = await NFTStakingFactory.deploy();
    await contract.waitForDeployment();

    nftStaking = contract as unknown as NFTStaking;
  });

  it("should allow a user to stake", async () => {
    await nftStaking.connect(alice).stake(5);
    const staked = await nftStaking.userStaked(alice.address);
    expect(staked).to.equal(5);
  });

  it("should allow a user to unstake", async () => {
    await nftStaking.connect(alice).stake(10);
    await nftStaking.connect(alice).unstake(4);
    const staked = await nftStaking.userStaked(alice.address);
    expect(staked).to.equal(6);
  });

  it("should calculate rewards correctly", async () => {
    await nftStaking.connect(alice).stake(5);
    const reward = await nftStaking.calculateRewards(alice.address);
    expect(reward).to.be.gte(0);
  });

  it("should fail when staking 0", async () => {
    await expect(nftStaking.connect(alice).stake(0))
      .to.be.revertedWith("Amount must be positive");
  });
});