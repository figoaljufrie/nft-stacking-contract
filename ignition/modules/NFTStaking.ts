import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const NFTStakingModule = buildModule("NFTStakingModule", (m) => {
  const nftStaking = m.contract("NFTStaking");

  return { nftStaking };
});

export default NFTStakingModule;