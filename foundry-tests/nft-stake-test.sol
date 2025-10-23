//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {NFTStaking} from "../contracts/nft-stake.sol";
import {Test} from "forge-std/Test.sol";

contract NFTStakingTest is Test {
    NFTStaking staking;

    //users to simulate multiple wallets:
    address alice = address(0x1);
    address bob = address(0x2);
    //0x1, 0x2 is just a sample mock wallet address. Since the real wallet use 20-byte address.

    function setUp() public {
        //deploy the contract fresh before each test.
        staking = new NFTStaking();

        //mock-data for alice & bob wallet amounts.
        //Fund alice & Bob (if needed):
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);

        /*
note; mental model.
Wallet: balance of a users to make a certain transactions.
  - wallet can hold eth, token (erc20), nft(erc721 or erc1155), any on-chain data linked to that address.

Stake: The act of locking or depositing an asset into a smart contract for a specific purpose -- example;
  - to earn rewards,
  - to participate in governence,
  - or to secure a network.
*/
    }

    //test initial owner & totalStaked:
    function test_initialstate() public view {
        //This logics require owner and its own wallet? So that bob using bob and alice using alice's wallet?

        //address(this) refers to the contract that is running the test. In this case is the nft-staking-contracts.
        require(
            staking.owner() == address(this),
            "Owner should be the deployer"
        );

        //The start of totalStaked (before transactions).
        require(staking.totalStaked() == 0, "Total staked should start from 0");
    }

    //Test staking function:
    function test_Stake() public {
        //refer the mock-data.
        vm.prank(alice); //simulate transaction from Alice.

        //refer-the stake transactions simulation, in this case: alice stakes 5 units. Before, Alice has 0.
        staking.stake(5);
        //After staking, alice has 5 stakes.

        //Validation when Alice is doing the transaction.
        require(staking.userStaked(alice) == 5, "Alice should have 5 staked");

        //Total stake should also update:
        //Validation to make sure the totalstaked starts from 0, and also increment when the transaction of Alice happened.
        require(
            staking.totalStaked() == 5,
            "Total staked should be 5, since alice make transaction of 5 stakes"
        );
    }

    //Test unstaking function
    function test_Unstake() public {
        //Refers the staker.
        vm.prank(alice);
        staking.stake(5);
        //value from the stake process earlier.

        //Refers how much she wamts to unstake, in this case, 3.
        vm.prank(alice);
        staking.unstake(3);

        //After unstaking, Alice have (5 (staked) - 3(unstake) = 2 total stakes left.)
        //unstaking means cancelled? Or remove her stakes from the contract, back to her account?
        //so total-staked is 2, while Alice's wallet is 8.

        require(
            staking.userStaked(alice) == 2,
            "Alice should have 2 staked left"
        );
        require(staking.totalStaked() == 2, "Total staked should be 2");

        //test-unstake to make total Stakes = 0
        vm.prank(alice);
        staking.unstake(2);
        require(
            staking.userStaked(alice) == 0,
            "Alice should have 0 staked left"
        );
        require(
            staking.totalStaked() == 0,
            "Total staked after Alice unstake should be 0"
        );
    }

    //test require conditions:
    //A test to give validation if stakes conditions failed.
    function test_FailUnstake() public {
        //referer
        vm.prank(alice);
        //staking 5.
        staking.stake(5);

        //validation:
        vm.expectRevert("Not enough staked");
        //then, alice, tries to unstake 10.
        vm.prank(alice);
        //It will automatically revert (throws error), since alice only stake 5 stakes.
        staking.unstake(10);
    }

    function test_FailStakeZero() public {
        vm.prank(alice);
        vm.expectRevert("Amount must be positive");
        staking.stake(0);
    }

    function test_CalculateRewards() public {
        //refererr:
        vm.prank(bob);
        //amount of the stake's that bob's put in the contract.
        staking.stake(7);

        //calculate how much bob's has already staked. If he stakes again, the calculateRewards will increment, adjusting based on the total stakes of bob.
        uint256 rewardsA = staking.calculateRewards(bob);
        require(rewardsA == 7, "Bob's reward should equal his stake");

        vm.prank(alice);
        staking.stake(5);

        uint256 rewardsB = staking.calculateRewards(alice);
        require(rewardsB == 5, "Alice's reward should equal her stake");

        require(
            staking.totalStaked() == 12,
            "Total Staked should be 12 after bob's & alice recent"
        );
    }

    function test_ClaimRewardsAfterTime() public {
        vm.prank(alice);
        staking.stake(10);
        //fast-forward 3 days after staking.
        vm.warp(block.timestamp + 3 days);
        // logics for reward staking. 10 stake * 1e16(1%gwei) * 3 days / 1 days.
        uint256 expectedReward = (10 * 1e16 /*1% of gwei*/ * 3 days) / 1 days; //equivalent of 0.3 token.

        uint256 actualReward = staking.calculateRewards(alice);
        assertEq(actualReward, expectedReward, "Reward calculation mismatch");

        //Alice claims the reward
        vm.prank(alice);
        staking.claimRewards();

        //after claim, timestamp reset to current block.
        assertEq(
            staking.stakeTimestamps(alice),
            block.timestamp,
            "Timestamp not reset after claim"
        );

        /*
      note;
      asserteq functionality:
        - logs both value, in this case: stakeTimestmamps and block.timestamp
        - Also, actual reward, and expected reward.
        - automatically stops the test and gives a clear diff in the terminal.
        - optimized for numeric, string, or bytes comparison.
        - works better with forge test to show where and why the failure happened.
       */
    }
}
