// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "./Setup.t.sol";

contract RewardTokenStakingManagerTest is RewardTokenSetUp {
    event StakingManagerUpdated(address indexed oldManager, address indexed newManager);

    function testSetStakingManager() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, false);
        emit StakingManagerUpdated(address(0), stakingManager);
        rewardToken.setStakingManager(stakingManager);
        assertEq(rewardToken.stakingManager(), stakingManager);
        vm.stopPrank();
    }

    function testNonOwnerCannotSetStakingManager() public {
        vm.startPrank(user1);
        vm.expectRevert();
        rewardToken.setStakingManager(stakingManager);
        vm.stopPrank();
    }

    function testCannotSetZeroAddressAsStakingManager() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid manager address");
        rewardToken.setStakingManager(address(0));
        vm.stopPrank();
    }

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

    function testNonStakingManagerCannotMint() public {
        vm.startPrank(user1);
        vm.expectRevert("Not Authorized");
        rewardToken.mint(user1, 100 * 10 ** 18);
        vm.stopPrank();
    }

    function testCannotMintBeyondMaxSupply() public {
        vm.startPrank(owner);
        rewardToken.setStakingManager(stakingManager);
        vm.stopPrank();

        uint256 excessAmount = 9_000_001 * 10 ** 18;
        vm.startPrank(stakingManager);
        vm.expectRevert("Exceeds max supply");
        rewardToken.mint(user1, excessAmount);
        vm.stopPrank();
    }

    function testMintUpToMaxSupply() public {
        vm.startPrank(owner);
        rewardToken.setStakingManager(stakingManager);
        vm.stopPrank();

        uint256 remainingAmount = 9_000_000 * 10 ** 18;
        vm.startPrank(stakingManager);
        rewardToken.mint(user1, remainingAmount);
        vm.stopPrank();

        assertEq(rewardToken.totalSupply(), 10_000_000 * 10 ** 18);
    }

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
        assertEq(rewardToken.totalSupply(), 1_000_000 * 10 ** 18 + 3 * mintAmount);
    }

    function testUpdateStakingManager() public {
        address newStakingManager = address(0x5);
        vm.startPrank(owner);
        rewardToken.setStakingManager(stakingManager);

        vm.expectEmit(true, true, false, false);
        emit StakingManagerUpdated(stakingManager, newStakingManager);

        rewardToken.setStakingManager(newStakingManager);
        assertEq(rewardToken.stakingManager(), newStakingManager);
        vm.stopPrank();

        vm.startPrank(stakingManager);
        vm.expectRevert("Not Authorized");
        rewardToken.mint(user1, 100 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(newStakingManager);
        rewardToken.mint(user1, 100 * 10 ** 18);
        vm.stopPrank();
    }
}