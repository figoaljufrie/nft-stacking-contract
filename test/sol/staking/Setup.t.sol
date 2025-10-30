// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/reward/Reward-token-V1.sol";
import "../../../contracts/staking/Staking-manager-V1.sol";
import "../../../contracts/mocks/MockNFT.sol";

contract StakingManagerSetupTest is Test {
    RewardTokenUpgradeable public rewardToken;
    StakingManagerUpgradeable public stakingManager;
    MockNFT public mockNFT;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    uint256 public rewardRate = 1e18;

    function setUp() public {
        vm.startPrank(owner);
        mockNFT = new MockNFT();
        rewardToken = new RewardTokenUpgradeable();
        rewardToken.initialize("Reward Token", "RWT", owner);

        stakingManager = new StakingManagerUpgradeable();
        stakingManager.initialize(
            address(mockNFT),
            address(rewardToken),
            rewardRate,
            owner
        );
        rewardToken.setStakingManager(address(stakingManager));
        vm.stopPrank();

        vm.startPrank(user1);
        mockNFT.mint(user1);
        mockNFT.mint(user1);
        vm.stopPrank();

        vm.startPrank(user2);
        mockNFT.mint(user2);
        vm.stopPrank();
    }

    function testInitialState() public view {
        assertEq(address(stakingManager.nftCollection()), address(mockNFT));
        assertEq(address(stakingManager.rewardToken()), address(rewardToken));
        assertEq(stakingManager.rewardRate(), rewardRate);
        assertEq(stakingManager.owner(), owner);
        assertEq(stakingManager.paused(), false);
    }

    function testVersion() public view {
        assertEq(stakingManager.version(), "1.0.0");
    }

    // Test set NFT collection (owner only)
    function testSetNFTCollection() public {
        MockNFT newNFT = new MockNFT();
        
        vm.startPrank(owner);
        
        stakingManager.setNFTCollection(address(newNFT));
        
        assertEq(address(stakingManager.nftCollection()), address(newNFT));
        
        vm.stopPrank();
    }
}
