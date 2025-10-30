// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../contracts/reward/Reward-token-V1.sol";
import "../../contracts/staking/Staking-manager-V1.sol";
import "../../contracts/mocks/MockNFT.sol";

contract StakingManagerUpgradeableTest is Test {
    RewardTokenUpgradeable public rewardToken;
    StakingManagerUpgradeable public stakingManager;
    MockNFT public mockNFT;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    uint256 public rewardRate = 1e18; // 1 token per NFT/sec

    // Events to test
    event Staked(address indexed user, uint256 indexed tokenId);
    event Withdrawn(address indexed user, uint256 indexed tokenId);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event Paused();
    event Unpaused();

    function setUp() public {
        // Deploy contracts as owner
        vm.startPrank(owner);
        
        // Deploy mock NFT
        mockNFT = new MockNFT();

        // Deploy reward token
        rewardToken = new RewardTokenUpgradeable();
        rewardToken.initialize("Reward Token", "RWT", owner);

        // Deploy staking manager
        stakingManager = new StakingManagerUpgradeable();
        stakingManager.initialize(
            address(mockNFT),
            address(rewardToken),
            rewardRate,
            owner
        );
        
        // Set staking manager in reward token
        rewardToken.setStakingManager(address(stakingManager));
        
        vm.stopPrank();

        // Mint NFTs to users for testing
        vm.startPrank(user1);
        mockNFT.mint(user1);
        mockNFT.mint(user1);
        vm.stopPrank();

        vm.startPrank(user2);
        mockNFT.mint(user2);
        vm.stopPrank();
    }

    // Test initial state
    function testInitialState() public {
        assertEq(address(stakingManager.nftCollection()), address(mockNFT));
        assertEq(address(stakingManager.rewardToken()), address(rewardToken));
        assertEq(stakingManager.rewardRate(), rewardRate);
        assertEq(stakingManager.owner(), owner);
        assertEq(stakingManager.paused(), false);
    }

    // Test stake NFTs
    function testStakeNFTs() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;

        mockNFT.setApprovalForAll(address(stakingManager), true);
        
        stakingManager.stake(tokenIds);

        // Check that 2 NFTs are staked
        (uint256[] memory staked, , uint256 acc) = stakingManager.getUserStakeInfo(user1);
        assertEq(staked.length, 2);
        assertEq(staked[0], 0);
        assertEq(staked[1], 1);
        assertEq(acc, 0); // accumulated reward initially 0

        // Check NFTs are owned by staking contract
        assertEq(mockNFT.ownerOf(0), address(stakingManager));
        assertEq(mockNFT.ownerOf(1), address(stakingManager));

        vm.stopPrank();
    }

    // Test stake single NFT
    function testStakeSingleNFT() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        (uint256[] memory staked, , ) = stakingManager.getUserStakeInfo(user1);
        assertEq(staked.length, 1);
        assertEq(staked[0], 0);

        vm.stopPrank();
    }

    // Test stake without approval fails
    function testStakeWithoutApprovalFails() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        vm.expectRevert();
        stakingManager.stake(tokenIds);

        vm.stopPrank();
    }

    // Test stake empty array fails
    function testStakeEmptyArrayFails() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](0);

        vm.expectRevert("No tokens provided");
        stakingManager.stake(tokenIds);

        vm.stopPrank();
    }

    // Test reward accumulation
    function testRewardAccumulation() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;

        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        // Simulate 10 seconds passing
        vm.warp(block.timestamp + 10);
        
        // Pending reward = rewardRate * number of NFTs * time
        (, , , uint256 pending) = stakingManager.getFullStake(user1);
        assertEq(pending, 2 * rewardRate * 10);
        
        vm.stopPrank();
    }

    // Test reward accumulation with single NFT
    function testRewardAccumulationSingleNFT() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        vm.warp(block.timestamp + 5);
        
        uint256 pending = stakingManager.pendingRewards(user1);
        assertEq(pending, rewardRate * 5);
        
        vm.stopPrank();
    }

    // Test claim rewards
    function testClaimRewards() public {
        vm.startPrank(user1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);
        
        vm.warp(block.timestamp + 5); // 5 seconds delay

        uint256 beforeBalance = rewardToken.balanceOf(user1);
        stakingManager.claimRewards();
        uint256 afterBalance = rewardToken.balanceOf(user1);
        
        // User should receive 5 tokens * 1 nft
        assertEq(afterBalance - beforeBalance, 5 * rewardRate);
        
        vm.stopPrank();
    }

    // Test claim rewards multiple times
    function testClaimRewardsMultipleTimes() public {
        vm.startPrank(user1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);
        
        // First claim after 5 seconds
        vm.warp(block.timestamp + 5);
        stakingManager.claimRewards();
        uint256 balance1 = rewardToken.balanceOf(user1);
        assertEq(balance1, 5 * rewardRate);
        
        // Second claim after another 3 seconds
        vm.warp(block.timestamp + 3);
        stakingManager.claimRewards();
        uint256 balance2 = rewardToken.balanceOf(user1);
        assertEq(balance2, 8 * rewardRate);
        
        vm.stopPrank();
    }

    // Test claim zero rewards fails
    function testClaimZeroRewardsFails() public {
        vm.startPrank(user1);
        
        vm.expectRevert("No rewards available");
        stakingManager.claimRewards();
        
        vm.stopPrank();
    }

    // Test withdraw NFTs and rewards
    function testWithdrawNFTsAndRewards() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;

        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        vm.warp(block.timestamp + 10); // 10 secs
        
        // Withdraw NFTs
        stakingManager.withdraw(tokenIds);
        
        (uint256[] memory staked, , ) = stakingManager.getUserStakeInfo(user1);
        assertEq(staked.length, 0);

        // Check NFTs are back with user
        assertEq(mockNFT.ownerOf(0), user1);
        assertEq(mockNFT.ownerOf(1), user1);

        // Claim rewards after withdrawal
        uint256 beforeBalance = rewardToken.balanceOf(user1);
        stakingManager.claimRewards();
        uint256 afterBalance = rewardToken.balanceOf(user1);

        // Should receive reward for 2 NFTs * 10 secs
        assertEq(afterBalance - beforeBalance, 2 * rewardRate * 10);
        
        vm.stopPrank();
    }

    // Test withdraw single NFT
    function testWithdrawSingleNFT() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;

        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        // Withdraw only one NFT
        uint256[] memory withdrawIds = new uint256[](1);
        withdrawIds[0] = 0;
        stakingManager.withdraw(withdrawIds);
        
        (uint256[] memory staked, , ) = stakingManager.getUserStakeInfo(user1);
        assertEq(staked.length, 1);
        assertEq(staked[0], 1); // Only token 1 should remain

        vm.stopPrank();
    }

    // Test withdraw unstaked token fails
    function testWithdrawUnstakedTokenFails() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        vm.expectRevert("Token not staked");
        stakingManager.withdraw(tokenIds);

        vm.stopPrank();
    }

    // Test emergency unstake
    function testEmergencyUnstake() public {
        vm.startPrank(user2);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2;
        
        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        vm.warp(block.timestamp + 5);

        // Emergency unstake
        stakingManager.emergencyUnstake(tokenIds);

        (uint256[] memory staked, , uint256 acc) = stakingManager.getUserStakeInfo(user2);
        assertEq(staked.length, 0);
        
        // Rewards should still be accumulated
        assertEq(acc, 5 * rewardRate);

        vm.stopPrank();
    }

    // Test set reward rate (owner only)
    function testSetRewardRate() public {
        uint256 newRate = 2e18;
        
        vm.startPrank(owner);
        
        vm.expectEmit(false, false, false, true);
        emit RewardRateUpdated(rewardRate, newRate);
        
        stakingManager.setRewardRate(newRate);
        
        assertEq(stakingManager.rewardRate(), newRate);
        
        vm.stopPrank();
    }

    // Test non-owner cannot set reward rate
    function testNonOwnerCannotSetRewardRate() public {
        vm.startPrank(user1);
        
        vm.expectRevert();
        stakingManager.setRewardRate(2e18);
        
        vm.stopPrank();
    }

    // Test pause functionality
    function testPauseStaking() public {
        vm.startPrank(owner);
        
        vm.expectEmit(false, false, false, false);
        emit Paused();
        
        stakingManager.setPaused(true);
        
        assertTrue(stakingManager.paused());
        
        vm.stopPrank();
    }

    // Test unpause functionality
    function testUnpauseStaking() public {
        vm.startPrank(owner);
        
        stakingManager.setPaused(true);
        
        vm.expectEmit(false, false, false, false);
        emit Unpaused();
        
        stakingManager.setPaused(false);
        
        assertFalse(stakingManager.paused());
        
        vm.stopPrank();
    }

    // Test staking fails when paused
    function testStakingFailsWhenPaused() public {
        vm.startPrank(owner);
        stakingManager.setPaused(true);
        vm.stopPrank();

        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        
        mockNFT.setApprovalForAll(address(stakingManager), true);

        vm.expectRevert("Contract is paused");
        stakingManager.stake(tokenIds);
        
        vm.stopPrank();
    }

    // Test withdraw fails when paused
    function testWithdrawFailsWhenPaused() public {
        // Stake first
        vm.startPrank(user1);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);
        vm.stopPrank();

        // Pause
        vm.startPrank(owner);
        stakingManager.setPaused(true);
        vm.stopPrank();

        // Try to withdraw
        vm.startPrank(user1);
        vm.expectRevert("Contract is paused");
        stakingManager.withdraw(tokenIds);
        vm.stopPrank();
    }

    // Test claim fails when paused
    function testClaimFailsWhenPaused() public {
        // Stake and accumulate rewards
        vm.startPrank(user1);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);
        vm.warp(block.timestamp + 5);
        vm.stopPrank();

        // Pause
        vm.startPrank(owner);
        stakingManager.setPaused(true);
        vm.stopPrank();

        // Try to claim
        vm.startPrank(user1);
        vm.expectRevert("Contract is paused");
        stakingManager.claimRewards();
        vm.stopPrank();
    }

    // Test get staked tokens
    function testGetStakedTokens() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;

        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        uint256[] memory staked = stakingManager.getStakedTokens(user1);
        assertEq(staked.length, 2);
        assertEq(staked[0], 0);
        assertEq(staked[1], 1);

        vm.stopPrank();
    }

    // Test pending rewards
    function testPendingRewards() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        vm.warp(block.timestamp + 10);

        uint256 pending = stakingManager.pendingRewards(user1);
        assertEq(pending, 10 * rewardRate);

        vm.stopPrank();
    }

    // Test get full stake info
    function testGetFullStake() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;

        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        vm.warp(block.timestamp + 5);

        (uint256[] memory tokens, uint256 lastClaim, uint256 accumulated, uint256 pending) = 
            stakingManager.getFullStake(user1);

        assertEq(tokens.length, 2);
        assertEq(accumulated, 0);
        assertEq(pending, 2 * rewardRate * 5);

        vm.stopPrank();
    }

    // Test set NFT collection (owner only)
    function testSetNFTCollection() public {
        MockNFT newNFT = new MockNFT();
        
        vm.startPrank(owner);
        
        stakingManager.setNFTCollection(address(newNFT));
        
        assertEq(address(stakingManager.nftCollection()), address(newNFT));
        
        vm.stopPrank();
    }

    // Test set reward token (owner only)
    function testSetRewardToken() public {
        RewardTokenUpgradeable newToken = new RewardTokenUpgradeable();
        
        vm.startPrank(owner);
        
        stakingManager.setRewardToken(address(newToken));
        
        assertEq(address(stakingManager.rewardToken()), address(newToken));
        
        vm.stopPrank();
    }

    // Test version
    function testVersion() public {
        assertEq(stakingManager.version(), "1.0.0");
    }

    // Test multiple users staking
    function testMultipleUsersStaking() public {
        // User1 stakes
        vm.startPrank(user1);
        uint256[] memory tokenIds1 = new uint256[](2);
        tokenIds1[0] = 0;
        tokenIds1[1] = 1;
        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds1);
        vm.stopPrank();

        // User2 stakes
        vm.startPrank(user2);
        uint256[] memory tokenIds2 = new uint256[](1);
        tokenIds2[0] = 2;
        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds2);
        vm.stopPrank();

        // Check both users have staked
        uint256[] memory staked1 = stakingManager.getStakedTokens(user1);
        uint256[] memory staked2 = stakingManager.getStakedTokens(user2);

        assertEq(staked1.length, 2);
        assertEq(staked2.length, 1);
    }

    // Test reward rate change affects future rewards
    function testRewardRateChangeAffectsFutureRewards() public {
        vm.startPrank(user1);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);
        vm.stopPrank();

        // Wait 5 seconds at rate 1
        vm.warp(block.timestamp + 5);

        // Change rate to 2
        vm.startPrank(owner);
        stakingManager.setRewardRate(2e18);
        vm.stopPrank();

        // Wait another 5 seconds
        vm.warp(block.timestamp + 5);

        // Pending should be: 5*1e18 (old rate) + 5*2e18 (new rate) = 15e18
        uint256 pending = stakingManager.pendingRewards(user1);
        assertEq(pending, 20e18);
    }
}