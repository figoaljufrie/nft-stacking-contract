// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "./Setup.t.sol";

contract TreasuryVaultDepositTest is TreasuryVaultSetUp {
    event FundsDeposited(address indexed from, uint256 amount);

    function testDepositFunds() public {
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vm.expectEmit(true, false, false, true);
        emit FundsDeposited(user1, 100 ether);
        vault.depositFunds(100 ether);
        assertEq(vault.getBalance(), 100 ether);
        assertEq(token.balanceOf(user1), 900 ether);
        vm.stopPrank();
    }

    function testMultipleDeposits() public {
        vm.startPrank(user1);
        token.approve(address(vault), 500 ether);
        vault.depositFunds(200 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(vault), 500 ether);
        vault.depositFunds(300 ether);
        vm.stopPrank();

        assertEq(vault.getBalance(), 500 ether);
    }

    function testDepositZeroFails() public {
        vm.startPrank(user1);
        vm.expectRevert("Invalid amount");
        vault.depositFunds(0);
        vm.stopPrank();
    }

    function testDepositWithoutApprovalFails() public {
        vm.startPrank(user1);
        vm.expectRevert();
        vault.depositFunds(100 ether);
        vm.stopPrank();
    }

    function testDepositWhenPausedFails() public {
        vm.startPrank(owner);
        vault.pause();
        vm.stopPrank();

        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vm.expectRevert("Vault is paused");
        vault.depositFunds(100 ether);
        vm.stopPrank();
    }

    function testReentrancyProtectionDeposit() public {
        vm.startPrank(user1);
        token.approve(address(vault), 200 ether);
        vault.depositFunds(100 ether);
        vault.depositFunds(100 ether);
        vm.stopPrank();
        assertEq(vault.getBalance(), 200 ether);
    }
}
