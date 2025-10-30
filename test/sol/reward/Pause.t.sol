// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "./Setup.t.sol";

contract RewardTokenPauseTest is RewardTokenSetUp {

    function testPause() public {
        vm.startPrank(owner);
        rewardToken.pause();
        assertTrue(rewardToken.paused());
        vm.stopPrank();
    }

    function testUnpause() public {
        vm.startPrank(owner);
        rewardToken.pause();
        rewardToken.unpause();
        assertFalse(rewardToken.paused());
        vm.stopPrank();
    }

    function testNonOwnerCannotPause() public {
        vm.startPrank(user1);
        vm.expectRevert();
        rewardToken.pause();
        vm.stopPrank();
    }

    function testNonOwnerCannotUnpause() public {
        vm.startPrank(owner);
        rewardToken.pause();
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert();
        rewardToken.unpause();
        vm.stopPrank();
    }

    function testTransfersBlockedWhenPaused() public {
        vm.startPrank(owner);
        rewardToken.transfer(user1, 100 * 10 ** 18);
        rewardToken.pause();
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert();
        rewardToken.transfer(user2, 50 * 10 ** 18);
        vm.stopPrank();
    }

    function testMintingBlockedWhenPaused() public {
        vm.startPrank(owner);
        rewardToken.setStakingManager(stakingManager);
        rewardToken.pause();
        vm.stopPrank();

        vm.startPrank(stakingManager);
        vm.expectRevert();
        rewardToken.mint(user1, 100 * 10 ** 18);
        vm.stopPrank();
    }

    function testTransferWhenUnpaused() public {
        vm.startPrank(owner);
        rewardToken.pause();
        rewardToken.unpause();
        rewardToken.transfer(user1, 100 * 10 ** 18);
        assertEq(rewardToken.balanceOf(user1), 100 * 10 ** 18);
        vm.stopPrank();
    }
}