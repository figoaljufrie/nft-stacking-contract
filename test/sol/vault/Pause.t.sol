// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "./Setup.t.sol";

contract TreasuryVaultPauseTest is TreasuryVaultSetUp {
    event Paused();
    event Unpaused();

    function testPause() public {
        vm.startPrank(owner);
        vm.expectEmit(false, false, false, false);
        emit Paused();
        vault.pause();
        assertTrue(vault.paused());
        vm.stopPrank();
    }

    function testUnpause() public {
        vm.startPrank(owner);
        vault.pause();
        vm.expectEmit(false, false, false, false);
        emit Unpaused();
        vault.unpause();
        assertFalse(vault.paused());
        vm.stopPrank();
    }

    function testNonOwnerCannotPause() public {
        vm.startPrank(user1);
        vm.expectRevert();
        vault.pause();
        vm.stopPrank();
    }
}
