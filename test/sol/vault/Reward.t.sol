// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "./Setup.t.sol";

contract TreasuryVaultRewardTest is TreasuryVaultSetUp {
    event RewardSent(address indexed to, uint256 amount);

    function testSendReward() public {
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.depositFunds(100 ether);
        vm.stopPrank();

        uint256 user2BalanceBefore = token.balanceOf(user2);

        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit RewardSent(user2, 30 ether);
        vault.sendReward(user2, 30 ether);
        vm.stopPrank();

        assertEq(vault.getBalance(), 70 ether);
        assertEq(token.balanceOf(user2), user2BalanceBefore + 30 ether);
    }

    function testNonOwnerCannotSendReward() public {
        vm.startPrank(user1);
        vm.expectRevert();
        vault.sendReward(user2, 10 ether);
        vm.stopPrank();
    }

    function testSendRewardInsufficientBalance() public {
        vm.startPrank(owner);
        vm.expectRevert("Insufficient balance");
        vault.sendReward(user2, 100 ether);
        vm.stopPrank();
    }

    function testSendRewardZeroFails() public {
        vm.startPrank(owner);
        vm.expectRevert("invalid amount");
        vault.sendReward(user2, 0);
        vm.stopPrank();
    }

    function testSendRewardToZeroAddressFails() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid Recipient");
        vault.sendReward(address(0), 10 ether);
        vm.stopPrank();
    }

    function testSendRewardWhenPausedFails() public {
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.depositFunds(100 ether);
        vm.stopPrank();

        vm.startPrank(owner);
        vault.pause();
        vm.expectRevert("Vault is paused");
        vault.sendReward(user2, 10 ether);
        vm.stopPrank();
    }
}
