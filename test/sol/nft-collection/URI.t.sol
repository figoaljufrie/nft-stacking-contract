// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/nft-collection/NFTCollection.sol";

contract MyNFTURITest is Test {
    MyNFT public nft;
    address public owner = address(0x1);
    address public user1 = address(0x2);

    function setUp() public {
        vm.startPrank(owner);
        nft = new MyNFT(owner);
        vm.stopPrank();
    }

    function testSetBaseURI() public {
        vm.startPrank(owner);
        nft.setBaseURI("https://api.example.com/");
        nft.mint(user1, "1");
        assertEq(nft.tokenURI(1), "https://api.example.com/1");
        vm.stopPrank();
    }

    function testNonOwnerCannotSetBaseURI() public {
        vm.startPrank(user1);
        vm.expectRevert();
        nft.setBaseURI("https://api.example.com/");
        vm.stopPrank();
    }

    function testTokenURINonExistent() public {
        vm.expectRevert();
        nft.tokenURI(999);
    }
}