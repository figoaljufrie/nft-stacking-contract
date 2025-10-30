// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../contracts/reward/Reward-token-V1.sol";

contract RewardTokenUpgradeableTest is Test {
    RewardTokenUpgradeable public rewardToken;

    address public owner = address(0x1);
    address public stakingManager = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    // Events to test
    event StakingManagerUpdated(
        address indexed oldManager,
        address indexed newManager
    );

    function setUp() public {
        // Deploy and initialize reward token
        vm.startPrank(owner);
        rewardToken = new RewardTokenUpgradeable();
        rewardToken.initialize("Reward Token", "RWT", owner);
        vm.stopPrank();
    }

    // Test initial state
    function testInitialState() public {
        assertEq(rewardToken.name(), "Reward Token");
        assertEq(rewardToken.symbol(), "RWT");
        assertEq(rewardToken.owner(), owner);
        assertEq(rewardToken.decimals(), 18);
        assertEq(rewardToken.paused(), false);
        // Owner should receive 1M tokens initially
        assertEq(rewardToken.balanceOf(owner), 1_000_000 * 10 ** 18);
        assertEq(rewardToken.totalSupply(), 1_000_000 * 10 ** 18);
        assertEq(rewardToken.MAX_SUPPLY(), 10_000_000 * 10 ** 18);
    }

    // Test set staking manager
    function testSetStakingManager() public {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, false);
        emit StakingManagerUpdated(address(0), stakingManager);

        rewardToken.setStakingManager(stakingManager);

        assertEq(rewardToken.stakingManager(), stakingManager);

        vm.stopPrank();
    }

    // Test non-owner cannot set staking manager
    function testNonOwnerCannotSetStakingManager() public {
        vm.startPrank(user1);

        vm.expectRevert();
        rewardToken.setStakingManager(stakingManager);

        vm.stopPrank();
    }

    // Test cannot set zero address as staking manager
    function testCannotSetZeroAddressAsStakingManager() public {
        vm.startPrank(owner);

        vm.expectRevert("Invalid manager address");
        rewardToken.setStakingManager(address(0));

        vm.stopPrank();
    }

    // Test staking manager can mint
    function testStakingManagerCanMint() public {
        vm.startPrank(owner);
        rewardToken.setStakingManager(stakingManager);
        vm.stopPrank();

        uint256 mintAmount = 100 * 10 ** 18;

        vm.startPrank(stakingManager);
        rewardToken.mint(user1, mintAmount);
        vm.stopPrank();

        assertEq(rewardToken.balanceOf(user1), mintAmount);
        assertEq(rewardToken.totalSupply(), 1_000_000 * 10 ** 18 + mintAmount);
    }

    // Test non-staking-manager cannot mint
    function testNonStakingManagerCannotMint() public {
        vm.startPrank(user1);

        vm.expectRevert("Not Authorized");
        rewardToken.mint(user1, 100 * 10 ** 18);

        vm.stopPrank();
    }

    // Test cannot mint beyond max supply
    function testCannotMintBeyondMaxSupply() public {
        vm.startPrank(owner);
        rewardToken.setStakingManager(stakingManager);
        vm.stopPrank();

        // Try to mint more than max supply (10M total, 1M already minted)
        uint256 excessAmount = 9_000_001 * 10 ** 18;

        vm.startPrank(stakingManager);

        vm.expectRevert("Exceeds max supply");
        rewardToken.mint(user1, excessAmount);

        vm.stopPrank();
    }

    // Test mint up to max supply
    function testMintUpToMaxSupply() public {
        vm.startPrank(owner);
        rewardToken.setStakingManager(stakingManager);
        vm.stopPrank();

        // Mint remaining tokens (9M)
        uint256 remainingAmount = 9_000_000 * 10 ** 18;

        vm.startPrank(stakingManager);
        rewardToken.mint(user1, remainingAmount);
        vm.stopPrank();

        assertEq(rewardToken.totalSupply(), 10_000_000 * 10 ** 18);
    }

    // Test pause functionality
    function testPause() public {
        vm.startPrank(owner);

        rewardToken.pause();

        assertTrue(rewardToken.paused());

        vm.stopPrank();
    }

    // Test unpause functionality
    function testUnpause() public {
        vm.startPrank(owner);

        rewardToken.pause();
        rewardToken.unpause();

        assertFalse(rewardToken.paused());

        vm.stopPrank();
    }

    // Test non-owner cannot pause
    function testNonOwnerCannotPause() public {
        vm.startPrank(user1);

        vm.expectRevert();
        rewardToken.pause();

        vm.stopPrank();
    }

    // Test non-owner cannot unpause
    function testNonOwnerCannotUnpause() public {
        vm.startPrank(owner);
        rewardToken.pause();
        vm.stopPrank();

        vm.startPrank(user1);

        vm.expectRevert();
        rewardToken.unpause();

        vm.stopPrank();
    }

    // Test transfers blocked when paused
    function testTransfersBlockedWhenPaused() public {
        // Transfer some tokens to user1
        vm.startPrank(owner);
        rewardToken.transfer(user1, 100 * 10 ** 18);

        // Pause contract
        rewardToken.pause();
        vm.stopPrank();

        // Try to transfer - should fail
        vm.startPrank(user1);

        vm.expectRevert();
        rewardToken.transfer(user2, 50 * 10 ** 18);

        vm.stopPrank();
    }

    // Test minting blocked when paused
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

    // Test token transfer
    function testTransfer() public {
        uint256 transferAmount = 100 * 10 ** 18;

        vm.startPrank(owner);

        rewardToken.transfer(user1, transferAmount);

        assertEq(rewardToken.balanceOf(user1), transferAmount);
        assertEq(
            rewardToken.balanceOf(owner),
            1_000_000 * 10 ** 18 - transferAmount
        );

        vm.stopPrank();
    }

    // Test approve and transferFrom
    function testApproveAndTransferFrom() public {
        uint256 approveAmount = 200 * 10 ** 18;
        uint256 transferAmount = 100 * 10 ** 18;

        vm.startPrank(owner);
        rewardToken.approve(user1, approveAmount);
        vm.stopPrank();

        assertEq(rewardToken.allowance(owner, user1), approveAmount);

        vm.startPrank(user1);
        rewardToken.transferFrom(owner, user2, transferAmount);
        vm.stopPrank();

        assertEq(rewardToken.balanceOf(user2), transferAmount);
        assertEq(
            rewardToken.allowance(owner, user1),
            approveAmount - transferAmount
        );
    }

    // Test burn functionality
    function testBurn() public {
        uint256 burnAmount = 100 * 10 ** 18;
        uint256 initialSupply = rewardToken.totalSupply();
        uint256 initialBalance = rewardToken.balanceOf(owner);

        vm.startPrank(owner);

        rewardToken.burn(burnAmount);

        assertEq(rewardToken.balanceOf(owner), initialBalance - burnAmount);
        assertEq(rewardToken.totalSupply(), initialSupply - burnAmount);

        vm.stopPrank();
    }

    // Test burnFrom functionality
    function testBurnFrom() public {
        uint256 burnAmount = 100 * 10 ** 18;

        // Owner approves user1 to burn tokens
        vm.startPrank(owner);
        rewardToken.approve(user1, burnAmount);
        vm.stopPrank();

        uint256 initialSupply = rewardToken.totalSupply();
        uint256 initialBalance = rewardToken.balanceOf(owner);

        vm.startPrank(user1);
        rewardToken.burnFrom(owner, burnAmount);
        vm.stopPrank();

        assertEq(rewardToken.balanceOf(owner), initialBalance - burnAmount);
        assertEq(rewardToken.totalSupply(), initialSupply - burnAmount);
    }

    // Test version
    function testVersion() public {
        assertEq(rewardToken.version(), "1.0.0");
    }

    // Test multiple mints by staking manager
    function testMultipleMints() public {
        vm.startPrank(owner);
        rewardToken.setStakingManager(stakingManager);
        vm.stopPrank();

        uint256 mintAmount = 1000 * 10 ** 18;

        vm.startPrank(stakingManager);

        rewardToken.mint(user1, mintAmount);
        rewardToken.mint(user2, mintAmount);
        rewardToken.mint(user1, mintAmount);

        vm.stopPrank();

        assertEq(rewardToken.balanceOf(user1), 2 * mintAmount);
        assertEq(rewardToken.balanceOf(user2), mintAmount);
        assertEq(
            rewardToken.totalSupply(),
            1_000_000 * 10 ** 18 + 3 * mintAmount
        );
    }

    // Test update staking manager
    function testUpdateStakingManager() public {
        address newStakingManager = address(0x5);

        vm.startPrank(owner);

        rewardToken.setStakingManager(stakingManager);

        vm.expectEmit(true, true, false, false);
        emit StakingManagerUpdated(stakingManager, newStakingManager);

        rewardToken.setStakingManager(newStakingManager);

        assertEq(rewardToken.stakingManager(), newStakingManager);

        vm.stopPrank();

        // Old staking manager should not be able to mint
        vm.startPrank(stakingManager);

        vm.expectRevert("Not Authorized");
        rewardToken.mint(user1, 100 * 10 ** 18);

        vm.stopPrank();

        // New staking manager should be able to mint
        vm.startPrank(newStakingManager);
        rewardToken.mint(user1, 100 * 10 ** 18);
        vm.stopPrank();
    }

    // Test transfer when not paused
    function testTransferWhenUnpaused() public {
        vm.startPrank(owner);

        rewardToken.pause();
        rewardToken.unpause();

        // Should work after unpause
        rewardToken.transfer(user1, 100 * 10 ** 18);

        assertEq(rewardToken.balanceOf(user1), 100 * 10 ** 18);

        vm.stopPrank();
    }
}
