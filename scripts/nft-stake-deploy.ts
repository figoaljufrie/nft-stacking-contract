// import hre from "hardhat";
// import type { NFTStaking } from "../types/ethers-contracts/NFTStaking.js";
// import { createPublicClient, http } from "viem";
// import { localhost } from "viem/chains";

// async function main() {
//   // Access Viem client via Hardhat
//   const viemClient = createPublicClient({
//     chain: localhost,
//     transport: http("http://127.0.0.1:8545"),
//   });

//   // Get the deployer's account (the first signer)
//   const [deployer] = await hre.network.provider.send("eth_accounts");

//   // Get the compiled contract artifact
//   const artifact = await hre.artifacts.readArtifact("NFTStaking");

//   // Deploy contract via viem
//   const { contractAddress, transactionHash } = await hre.viem.deployContract({
//     abi: artifact.abi,
//     bytecode: artifact.bytecode,
//     account: deployer,
//     args: [], // constructor arguments if any
//   });

//   // You can typecast for TypeScript support
//   const staking = contractAddress as unknown as NFTStaking;

//   console.log("NFTStaking deployed to:", staking);
//   console.log("Transaction hash:", transactionHash);
// }

// // Standard error handling
// main().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });