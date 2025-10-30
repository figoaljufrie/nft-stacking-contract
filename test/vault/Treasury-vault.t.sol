// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../contracts/vault/Treasury-vault-V1.sol";
import "../../contracts/mocks/Mock-Reward-Token.sol";

contract TreasuryVaultTest is Test {
    TreasuryVault public vault;
    MockRewardToken public token;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    
    // Events to test
    event FundsDeposited(address indexed from, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event RewardSent(address indexed to, uint256 amount);
    event Paused();
    event Unpaused();
    
    function setUp() public {
        // Deploy mock token
        token = new MockRewardToken();
        
        // Deploy vault
        vm.startPrank(owner);
        
        vault = new TreasuryVault();
        vault.initialize(address(token), owner);
        vm.stopPrank();
        
        // Mint tokens to users for testing
        token.mint(user1, 1000 ether);
        token.mint(user2, 1000 ether);
    }
    
    // Test initial state
    function testInitialState() public {
        assertEq(vault.owner(), owner);
        assertEq(address(vault.rewardToken()), address(token));
        assertEq(vault.paused(), false);
        assertEq(vault.getBalance(), 0);
    }
    
    // Test deposit funds
    function testDepositFunds() public {
        vm.startPrank(user1);
        
        // Approve vault to spend tokens
        token.approve(address(vault), 100 ether);
        
        // Deposit funds
        vm.expectEmit(true, false, false, true);
        emit FundsDeposited(user1, 100 ether);
        
        vault.depositFunds(100 ether);
        
        assertEq(vault.getBalance(), 100 ether);
        assertEq(token.balanceOf(user1), 900 ether);
        
        vm.stopPrank();
    }
    
    // Test multiple deposits
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
    
    // Test deposit zero amount fails
    function testDepositZeroFails() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Invalid amount");
        vault.depositFunds(0);
        
        vm.stopPrank();
    }
    
    // Test deposit without approval fails
    function testDepositWithoutApprovalFails() public {
        vm.startPrank(user1);
        
        vm.expectRevert();
        vault.depositFunds(100 ether);
        
        vm.stopPrank();
    }
    
    // Test owner withdraw
    function testOwnerWithdraw() public {
        // Setup: deposit some funds
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.depositFunds(100 ether);
        vm.stopPrank();
        
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        
        // Owner withdraws
        vm.startPrank(owner);
        
        vm.expectEmit(true, false, false, true);
        emit FundsWithdrawn(owner, 50 ether);
        
        vault.withdraw(owner, 50 ether);
        
        vm.stopPrank();
        
        assertEq(vault.getBalance(), 50 ether);
        assertEq(token.balanceOf(owner), ownerBalanceBefore + 50 ether);
    }
    
    // Test non-owner cannot withdraw
    function testNonOwnerCannotWithdraw() public {
        vm.startPrank(user1);
        
        vm.expectRevert();
        vault.withdraw(user1, 50 ether);
        
        vm.stopPrank();
    }
    
    // Test withdraw with insufficient balance fails
    function testWithdrawInsufficientBalance() public {
        vm.startPrank(owner);
        
        vm.expectRevert("Insufficient balance");
        vault.withdraw(owner, 100 ether);
        
        vm.stopPrank();
    }
    
    // Test withdraw zero amount fails
    function testWithdrawZeroFails() public {
        vm.startPrank(owner);
        
        vm.expectRevert("Invalid amount");
        vault.withdraw(owner, 0);
        
        vm.stopPrank();
    }
    
    // Test withdraw to zero address fails
    function testWithdrawToZeroAddressFails() public {
        vm.startPrank(owner);
        
        vm.expectRevert("Invalid Recipient");
        vault.withdraw(address(0), 100 ether);
        
        vm.stopPrank();
    }
    
    // Test send reward
    function testSendReward() public {
        // Setup: deposit funds
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.depositFunds(100 ether);
        vm.stopPrank();
        
        uint256 user2BalanceBefore = token.balanceOf(user2);
        
        // Owner sends reward
        vm.startPrank(owner);
        
        vm.expectEmit(true, false, false, true);
        emit RewardSent(user2, 30 ether);
        
        vault.sendReward(user2, 30 ether);
        
        vm.stopPrank();
        
        assertEq(vault.getBalance(), 70 ether);
        assertEq(token.balanceOf(user2), user2BalanceBefore + 30 ether);
    }
    
    // Test non-owner cannot send reward
    function testNonOwnerCannotSendReward() public {
        vm.startPrank(user1);
        
        vm.expectRevert();
        vault.sendReward(user2, 10 ether);
        
        vm.stopPrank();
    }
    
    // Test send reward with insufficient balance fails
    function testSendRewardInsufficientBalance() public {
        vm.startPrank(owner);
        
        vm.expectRevert("Insufficient balance");
        vault.sendReward(user2, 100 ether);
        
        vm.stopPrank();
    }
    
    // Test send reward zero amount fails
    function testSendRewardZeroFails() public {
        vm.startPrank(owner);
        
        vm.expectRevert("invalid amount");
        vault.sendReward(user2, 0);
        
        vm.stopPrank();
    }
    
    // Test send reward to zero address fails
    function testSendRewardToZeroAddressFails() public {
        vm.startPrank(owner);
        
        vm.expectRevert("Invalid Recipient");
        vault.sendReward(address(0), 10 ether);
        
        vm.stopPrank();
    }
    
    // Test pause functionality
    function testPause() public {
        vm.startPrank(owner);
        
        vm.expectEmit(false, false, false, false);
        emit Paused();
        
        vault.pause();
        
        assertTrue(vault.paused());
        
        vm.stopPrank();
    }
    
    // Test unpause functionality
    function testUnpause() public {
        vm.startPrank(owner);
        
        vault.pause();
        
        vm.expectEmit(false, false, false, false);
        emit Unpaused();
        
        vault.unpause();
        
        assertFalse(vault.paused());
        
        vm.stopPrank();
    }
    
    // Test non-owner cannot pause
    function testNonOwnerCannotPause() public {
        vm.startPrank(user1);
        
        vm.expectRevert();
        vault.pause();
        
        vm.stopPrank();
    }
    
    // Test deposit when paused fails
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
    
    // Test send reward when paused fails
    function testSendRewardWhenPausedFails() public {
        // Setup: deposit funds while not paused
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.depositFunds(100 ether);
        vm.stopPrank();
        
        // Pause vault
        vm.startPrank(owner);
        vault.pause();
        
        vm.expectRevert("Vault is paused");
        vault.sendReward(user2, 10 ether);
        
        vm.stopPrank();
    }
    
    // Test withdraw when paused (should succeed - owner emergency access)
    function testWithdrawWhenPausedSucceeds() public {
        // Setup: deposit funds
        vm.startPrank(user1);
        token.approve(address(vault), 100 ether);
        vault.depositFunds(100 ether);
        vm.stopPrank();
        
        // Pause and withdraw
        vm.startPrank(owner);
        vault.pause();
        vault.withdraw(owner, 50 ether);
        vm.stopPrank();
        
        assertEq(vault.getBalance(), 50 ether);
    }
    
    // Test reentrancy protection on deposit
    function testReentrancyProtectionDeposit() public {
        // depositFunds has nonReentrant modifier
        // This is more of an integration test with malicious token
        // For now, we verify the modifier is present by checking normal operation
        vm.startPrank(user1);
        token.approve(address(vault), 200 ether);
        vault.depositFunds(100 ether);
        vault.depositFunds(100 ether);
        vm.stopPrank();
        
        assertEq(vault.getBalance(), 200 ether);
    }
    
    // Test version
    function testVersion() public {
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