// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "./Setup.t.sol";

contract RewardTokenTransferTest is RewardTokenSetUp {

    function testTransfer() public {
        uint256 transferAmount = 100 * 10 ** 18;
        vm.startPrank(owner);
        rewardToken.transfer(user1, transferAmount);
        assertEq(rewardToken.balanceOf(user1), transferAmount);
        assertEq(rewardToken.balanceOf(owner), 1_000_000 * 10 ** 18 - transferAmount);
        vm.stopPrank();
    }

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
        assertEq(rewardToken.allowance(owner, user1), approveAmount - transferAmount);
    }
}