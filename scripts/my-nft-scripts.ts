// @ts-ignore
import hre from "hardhat";

async function main() {
  console.log("🔹 Connecting to deployed contract...");

  // @ts-ignore - Hardhat v3 Viem not yet in types
  const { viem } = hre;

  // ✅ 1. Get deployer account (index 0)
  const owner = await viem.getAccount(0);

  // ✅ 2. Use your deployed contract address
  const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

  // ✅ 3. Connect to the deployed contract
  const nft = await viem.getContractAt("MyNFT", contractAddress);

  console.log("✅ Connected to MyNFT at:", nft.address);

  // ✅ 4. Read contract info
  const name = await nft.read.name();
  const symbol = await nft.read.symbol();
  console.log("Name:", name);
  console.log("Symbol:", symbol);

  // ✅ 5. Mint new NFT
  console.log("🪙 Minting new NFT...");
  const mintTx = await nft.write.mint([owner.address, "ipfs://token.json"], {
    account: owner,
  });
  console.log("Mint transaction hash:", mintTx);

  // ✅ 6. Check balance
  const balance = await nft.read.balanceOf([owner.address]);
  console.log(`Balance of ${owner.address}:`, balance.toString());

  // ✅ 7. Get tokenURI
  const tokenUri = await nft.read.tokenURI([1]);
  console.log("TokenURI(1):", tokenUri);
}

main().catch((err) => {
  console.error("❌ Error:", err);
  process.exit(1);
});