# NFT Staking Hardhat Project

This project showcases an NFT staking system built with **Hardhat 3 Beta**, using **node:test runner** for tests and **Viem** for Ethereum interactions.

It demonstrates a complete setup including:

- ERC721 NFT collection (`NFTCollection.sol`)
- Staking contract (`NFTStaking.sol`)
- Reward token (`RewardToken.sol`)
- Treasury / reward management contracts (planned)
- Modular folder structure for contracts and tests
- Frontend-ready events and interactions

---

## Project Overview

This project includes:

- Hardhat configuration file for compiling, testing, and deploying Solidity contracts
- Foundry-compatible Solidity unit tests
- TypeScript integration tests using `mocha` and Viem
- Examples demonstrating deployment to local chains and Sepolia testnet
- Modular contracts structure for NFT collection, staking logic, and reward tokens

**NOTES**
- This is my first attempt on entering the web-3 world.
- I have not had any interactions / solo-educations regarding web-3 before this.
- I chose this project to get to know the fundamentals / work-flow / general structures of web-3 world (DeFi, Front-end Integration, dApp implementation, Tokenomics)
- This will be a seperated Repository with my front-end.
- I will attempt on also creating a (very optional / pessimistic, actually.) back-end structure for the off-chain database.
- If there are any notes, advices, or any lecturing sessions that can help me get through this project, kindly hit-me-up or give me a comments.
- I use AI, of course (but trying to minimize and understand it on my own, hence there are a bunch of cluttering commments all over the files).

**P.S**
Early Issues (Will be updated gradually until the end of the project):
**- Hardhat.config setup:**
Based on the docs, hardhat v.3 requires node 22 or higher. Also, the early rise of this BETA version creates a very hard way in aligning it with typescript configuration.

**- Test:**
Especially for testing, i used Mocha / Chai before decided to migrate to node: test runnner. Why? From the hardhat docs that i read, it no longer support automated chai / mocha set-up like in the hardhat v.2, hence why you need to manually install Mocha / Chai. But the problem is, it's kinda hard on aligning between hardhat, mocha, chai, type-script, and node version. They must have do a little mishap between one another. Luckily the docs said that it is recommended to use the node: test, since it's work automatically with hardhut runtime environment.

**- Scripts:**
From what i know, before, we use scripts to deploy our already tested contracts. But, now we deploy in the ignition folders (as far as i know) since it cannot read my type-script file in the scripts folder.

*- Openzeppelin updated version:*
Since the update of openzeppelin 5.0, unlike before where it has many functions we can use, such as: _BeforeTokenTransfer, _AfterTokenTransfer, etc. Now openzep automatically do that logics internally. So we don't have to, unless we want to have other custom updating logics. We can use _update to override the existing functions.

THIS IS ONLY WRITTEN TO DOCUMENT MY PROJECT JOURNEY, IF THERE'S ANY MISINTERPRETED NOTES PLEAE REMIND ME KINDLY. THANKS!
