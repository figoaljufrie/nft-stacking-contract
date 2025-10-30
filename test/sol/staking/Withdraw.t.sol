// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/reward/Reward-token-V1.sol";
import "../../../contracts/staking/Staking-manager-V1.sol";
import "../../../contracts/mocks/MockNFT.sol";

contract StakingManagerWithdrawTest is Test {
    RewardTokenUpgradeable public rewardToken;
    StakingManagerUpgradeable public stakingManager;
    MockNFT public mockNFT;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    uint256 public rewardRate = 1e18;

    function setUp() public {
        vm.startPrank(owner);
        mockNFT = new MockNFT();
        rewardToken = new RewardTokenUpgradeable();
        rewardToken.initialize("Reward Token", "RWT", owner);

        stakingManager = new StakingManagerUpgradeable();
        stakingManager.initialize(
            address(mockNFT),
            address(rewardToken),
            rewardRate,
            owner
        );
        rewardToken.setStakingManager(address(stakingManager));
        vm.stopPrank();

        vm.startPrank(user1);
        mockNFT.mint(user1);
        mockNFT.mint(user1);
        vm.stopPrank();

        vm.startPrank(user2);
        mockNFT.mint(user2);
        vm.stopPrank();
    }

    function testWithdrawNFTsAndRewards() public {
        vm.startPrank(user1);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);
        vm.warp(block.timestamp + 10);
        stakingManager.withdraw(tokenIds);

        (uint256[] memory staked, , ) = stakingManager.getUserStakeInfo(user1);
        assertEq(staked.length, 0);
        assertEq(mockNFT.ownerOf(0), user1);
        assertEq(mockNFT.ownerOf(1), user1);

        uint256 beforeBalance = rewardToken.balanceOf(user1);
        stakingManager.claimRewards();
        uint256 afterBalance = rewardToken.balanceOf(user1);
        assertEq(afterBalance - beforeBalance, 2 * rewardRate * 10);
        vm.stopPrank();
    }

    function testEmergencyUnstake() public {
        vm.startPrank(user2);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2;
        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        vm.warp(block.timestamp + 5);
        stakingManager.emergencyUnstake(tokenIds);

        (uint256[] memory staked, , uint256 acc) = stakingManager
            .getUserStakeInfo(user2);
        assertEq(staked.length, 0);
        assertEq(acc, 5 * rewardRate);
        vm.stopPrank();
    }

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

    function testWithdrawUnstakedTokenFails() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;

        vm.expectRevert("Token not staked");
        stakingManager.withdraw(tokenIds);

        vm.stopPrank();
    }
}
