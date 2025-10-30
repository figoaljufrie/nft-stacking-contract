import { network } from "hardhat";

export async function deployContract() {
  const { viem: hreViem } = await network.connect("hardhat");
  const wallets = await hreViem.getWalletClients();
  const [owner, user1, user2] = wallets;

  const myNFT = await hreViem.deployContract("MyNFT", [owner.account.address], {
    client: {
      wallet: owner,
    },
  });
  return { myNFT, owner, user1, user2 };
}
