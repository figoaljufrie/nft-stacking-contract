// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/reward/Reward-token-V1.sol";

contract RewardTokenSetUp is Test {
    RewardTokenUpgradeable public rewardToken;

    address public owner = address(0x1);
    address public stakingManager = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    function setUp() public {
        vm.startPrank(owner);
        rewardToken = new RewardTokenUpgradeable();
        rewardToken.initialize("Reward Token", "RWT", owner);
        vm.stopPrank();
    }

    function testInitialState() public view{
        assertEq(rewardToken.name(), "Reward Token");
        assertEq(rewardToken.symbol(), "RWT");
        assertEq(rewardToken.owner(), owner);
        assertEq(rewardToken.decimals(), 18);
        assertEq(rewardToken.paused(), false);
        assertEq(rewardToken.balanceOf(owner), 1_000_000 * 10 ** 18);
        assertEq(rewardToken.totalSupply(), 1_000_000 * 10 ** 18);
        assertEq(rewardToken.MAX_SUPPLY(), 10_000_000 * 10 ** 18);
    }

    function testVersion() public view{
        assertEq(rewardToken.version(), "1.0.0");
    }
}