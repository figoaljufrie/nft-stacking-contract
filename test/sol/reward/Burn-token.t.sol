// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "./Setup.t.sol";

contract RewardTokenBurnTest is RewardTokenSetUp {

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

    function testBurnFrom() public {
        uint256 burnAmount = 100 * 10 ** 18;
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
}