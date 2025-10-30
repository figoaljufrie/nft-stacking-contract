// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/nft-collection/NFTCollection.sol";

contract MyNFTEnumerationTest is Test {
    MyNFT public nft;
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        nft = new MyNFT(owner);
        vm.stopPrank();
    }

    function testEnumeration() public {
        vm.startPrank(owner);
        nft.mint(user1, "ipfs://metadata1");
        nft.mint(user1, "ipfs://metadata2");
        nft.mint(user2, "ipfs://metadata3");
        vm.stopPrank();

        assertEq(nft.tokenByIndex(0), 1);
        assertEq(nft.tokenByIndex(1), 2);
        assertEq(nft.tokenByIndex(2), 3);

        assertEq(nft.tokenOfOwnerByIndex(user1, 0), 1);
        assertEq(nft.tokenOfOwnerByIndex(user1, 1), 2);
        assertEq(nft.tokenOfOwnerByIndex(user2, 0), 3);
    }

    function testSupportsInterface() public view {
        assertTrue(nft.supportsInterface(0x80ac58cd));
        assertTrue(nft.supportsInterface(0x780e9d63));
    }
}