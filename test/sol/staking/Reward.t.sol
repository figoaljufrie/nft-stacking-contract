// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/reward/Reward-token-V1.sol";
import "../../../contracts/staking/Staking-manager-V1.sol";
import "../../../contracts/mocks/MockNFT.sol";

contract StakingManagerRewardsTest is Test {
    RewardTokenUpgradeable public rewardToken;
    StakingManagerUpgradeable public stakingManager;
    MockNFT public mockNFT;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    uint256 public rewardRate = 1e18;

    event RewardRateUpdated(uint256 oldRate, uint256 newRate);

    function setUp() public {
        vm.startPrank(owner);
        mockNFT = new MockNFT();
        rewardToken = new RewardTokenUpgradeable();
        rewardToken.initialize("Reward Token", "RWT", owner);

        stakingManager = new StakingManagerUpgradeable();
        stakingManager.initialize(address(mockNFT), address(rewardToken), rewardRate, owner);
        rewardToken.setStakingManager(address(stakingManager));
        vm.stopPrank();

        vm.startPrank(user1);
        mockNFT.mint(user1);
        vm.stopPrank();
    }

    function testRewardAccumulation() public {
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

    function testClaimRewards() public {
        vm.startPrank(user1);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        vm.warp(block.timestamp + 5);
        uint256 beforeBalance = rewardToken.balanceOf(user1);
        stakingManager.claimRewards();
        uint256 afterBalance = rewardToken.balanceOf(user1);

        assertEq(afterBalance - beforeBalance, 5 * rewardRate);
        vm.stopPrank();
    }

    function testClaimRewardsMultipleTimes() public {
        vm.startPrank(user1);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        vm.warp(block.timestamp + 5);
        stakingManager.claimRewards();
        uint256 balance1 = rewardToken.balanceOf(user1);

        vm.warp(block.timestamp + 3);
        stakingManager.claimRewards();
        uint256 balance2 = rewardToken.balanceOf(user1);

        assertEq(balance1, 5 * rewardRate);
        assertEq(balance2, 8 * rewardRate);
        vm.stopPrank();
    }

    function testClaimZeroRewardsFails() public {
        vm.startPrank(user1);
        vm.expectRevert("No rewards available");
        stakingManager.claimRewards();
        vm.stopPrank();
    }

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
}