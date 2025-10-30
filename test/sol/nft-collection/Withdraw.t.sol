// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/nft-collection/NFTCollection.sol";

contract MyNFTWithdrawTest is Test {
    MyNFT public nft;
    address public owner = address(0x1);
    address public user1 = address(0x2);

    function setUp() public {
        vm.startPrank(owner);
        nft = new MyNFT(owner);
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(owner);
        nft.setMintPrice(0.1 ether);
        vm.stopPrank();

        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        nft.mintPublic{value: 0.1 ether}("ipfs://metadata1");
        vm.stopPrank();

        uint256 ownerBalanceBefore = owner.balance;
        uint256 contractBalance = address(nft).balance;

        vm.startPrank(owner);
        nft.withdraw();
        vm.stopPrank();

        assertEq(address(nft).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + contractBalance);
    }

    function testWithdrawNoFunds() public {
        vm.startPrank(owner);
        vm.expectRevert("No funds to withdraw");
        nft.withdraw();
        vm.stopPrank();
    }

    function testNonOwnerCannotWithdraw() public {
        vm.startPrank(user1);
        vm.expectRevert();
        nft.withdraw();
        vm.stopPrank();
    }
}