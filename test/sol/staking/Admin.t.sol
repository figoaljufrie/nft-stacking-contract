// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/reward/Reward-token-V1.sol";
import "../../../contracts/staking/Staking-manager-V1.sol";
import "../../../contracts/mocks/MockNFT.sol";

contract StakingManagerAdminTest is Test {
    RewardTokenUpgradeable public rewardToken;
    StakingManagerUpgradeable public stakingManager;
    MockNFT public mockNFT;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    uint256 public rewardRate = 1e18;

    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event Paused();
    event Unpaused();

    function setUp() public {
        vm.startPrank(owner);
        mockNFT = new MockNFT();
        rewardToken = new RewardTokenUpgradeable();
        rewardToken.initialize("Reward Token", "RWT", owner);

        stakingManager = new StakingManagerUpgradeable();
        stakingManager.initialize(address(mockNFT), address(rewardToken), rewardRate, owner);
        rewardToken.setStakingManager(address(stakingManager));
        vm.stopPrank();
    }
function testSetRewardToken() public {
        RewardTokenUpgradeable newToken = new RewardTokenUpgradeable();
        vm.startPrank(owner);
        stakingManager.setRewardToken(address(newToken));
        assertEq(address(stakingManager.rewardToken()), address(newToken));
        vm.stopPrank();
    }

}