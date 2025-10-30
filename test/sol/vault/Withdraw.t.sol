// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "./Setup.t.sol";

contract TreasuryVaultWithdrawTest is TreasuryVaultSetUp {
    event FundsWithdrawn(address indexed to, uint256 amount);

    function testOwnerWithdraw() public {
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.depositFunds(100 ether);
        vm.stopPrank();

        uint256 ownerBalanceBefore = token.balanceOf(owner);

        vm.startPrank(owner);
        vm.expectEmit(true, false, false, true);
        emit FundsWithdrawn(owner, 50 ether);
        vault.withdraw(owner, 50 ether);
        vm.stopPrank();

        assertEq(vault.getBalance(), 50 ether);
        assertEq(token.balanceOf(owner), ownerBalanceBefore + 50 ether);
    }

    function testNonOwnerCannotWithdraw() public {
        vm.startPrank(user1);
        vm.expectRevert();
        vault.withdraw(user1, 50 ether);
        vm.stopPrank();
    }

    function testWithdrawInsufficientBalance() public {
        vm.startPrank(owner);
        vm.expectRevert("Insufficient balance");
        vault.withdraw(owner, 100 ether);
        vm.stopPrank();
    }

    function testWithdrawZeroFails() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid amount");
        vault.withdraw(owner, 0);
        vm.stopPrank();
    }

    function testWithdrawToZeroAddressFails() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid Recipient");
        vault.withdraw(address(0), 100 ether);
        vm.stopPrank();
    }

    function testWithdrawWhenPausedSucceeds() public {
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.depositFunds(100 ether);
        vm.stopPrank();

        vm.startPrank(owner);
        vault.pause();
        vault.withdraw(owner, 50 ether);
        vm.stopPrank();

        assertEq(vault.getBalance(), 50 ether);
    }
}
