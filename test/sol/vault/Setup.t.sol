// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/vault/Treasury-vault-V1.sol";
import "../../../contracts/mocks/Mock-Reward-Token.sol";

contract TreasuryVaultSetUp is Test {
    TreasuryVault public vault;
    MockRewardToken public token;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    function setUp() public {
        token = new MockRewardToken();
        vm.startPrank(owner);
        vault = new TreasuryVault();
        vault.initialize(address(token), owner);
        vm.stopPrank();
        token.mint(user1, 1000 ether);
        token.mint(user2, 1000 ether);
    }

    // Test initial state
    function testInitialState() public view{
        assertEq(vault.owner(), owner);
        assertEq(address(vault.rewardToken()), address(token));
        assertEq(vault.paused(), false);
        assertEq(vault.getBalance(), 0);
    }

    // Test version
    function testVersion() public view{
        assertEq(vault.version(), "1.0.0");
    }

    // Test get balance
    function testGetBalance() public {
        assertEq(vault.getBalance(), 0);
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.depositFunds(100 ether);
        vm.stopPrank();
        assertEq(vault.getBalance(), 100 ether);
    }
}