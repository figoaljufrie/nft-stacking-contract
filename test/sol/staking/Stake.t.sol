// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/reward/Reward-token-V1.sol";
import "../../../contracts/staking/Staking-manager-V1.sol";
import "../../../contracts/mocks/MockNFT.sol";

contract StakingManagerStakeTest is Test {
    RewardTokenUpgradeable public rewardToken;
    StakingManagerUpgradeable public stakingManager;
    MockNFT public mockNFT;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    uint256 public rewardRate = 1e18;

    event Paused();
    event Unpaused();

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

    function testStakeNFTs() public {
        vm.startPrank(user1);
        uint256[] memory tokenIds = new uint256[](2);
        
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        mockNFT.setApprovalForAll(address(stakingManager), true);
        stakingManager.stake(tokenIds);

        (uint256[] memory staked, , uint256 acc) = stakingManager
            .getUserStakeInfo(user1);
        assertEq(staked.length, 2);
        assertEq(staked[0], 0);
        assertEq(staked[1], 1);
        assertEq(acc, 0);
        assertEq(mockNFT.ownerOf(0), address(stakingManager));
        assertEq(mockNFT.ownerOf(1), address(stakingManager));
        vm.stopPrank();
    }

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

    function testStakeWithoutApprovalFails() public {
        vm.startPrank(user1);
        uint256[] memory tokenIds = new uint256[](1);

        tokenIds[0] = 0;
        vm.expectRevert();
        stakingManager.stake(tokenIds);
        vm.stopPrank();
    }

   function testStakeEmptyArrayFails() public {
        vm.startPrank(user1);
        
        uint256[] memory tokenIds = new uint256[](0);

        vm.expectRevert("No tokens provided");
        stakingManager.stake(tokenIds);

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
}
