// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/nft-collection/NFTCollection.sol";

contract MyNFTTransferBurnTest is Test {
    MyNFT public nft;
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        nft = new MyNFT(owner);
        vm.stopPrank();
    }

    function testTransfer() public {
        vm.startPrank(owner);
        nft.mint(user1, "ipfs://metadata1");
        vm.stopPrank();

        vm.startPrank(user1);
        nft.transferFrom(user1, user2, 1);
        vm.stopPrank();

        assertEq(nft.ownerOf(1), user2);
        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(user2), 1);
    }

    function testBurn() public {
        vm.startPrank(owner);
        nft.mint(user1, "ipfs://metadata1");
        vm.stopPrank();

        vm.startPrank(user1);
        nft.burn(1);
        vm.stopPrank();

        assertEq(nft.totalSupply(), 0);
        assertEq(nft.balanceOf(user1), 0);
    }
}