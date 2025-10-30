// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/nft-collection/NFTCollection.sol";

contract MyNFTMintingTest is Test {
    MyNFT public nft;
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        nft = new MyNFT(owner);
        vm.stopPrank();
    }

    function testOwnerMint() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.mint(user1, "ipfs://metadata1");
        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.tokenURI(1), "ipfs://metadata1");
        vm.stopPrank();
    }

    function testMultipleOwnerMints() public {
        vm.startPrank(owner);
        nft.mint(user1, "ipfs://metadata1");
        nft.mint(user1, "ipfs://metadata2");
        nft.mint(user2, "ipfs://metadata3");
        assertEq(nft.totalSupply(), 3);
        assertEq(nft.balanceOf(user1), 2);
        assertEq(nft.balanceOf(user2), 1);
        vm.stopPrank();
    }

    function testNonOwnerCannotMint() public {
        vm.startPrank(user1);
        vm.expectRevert();
        nft.mint(user1, "ipfs://metadata1");
        vm.stopPrank();
    }

    function testSetMintPrice() public {
        vm.startPrank(owner);
        nft.setMintPrice(0.1 ether);
        assertEq(nft.mintPrice(), 0.1 ether);
        vm.stopPrank();
    }

    function testNonOwnerCannotSetMintPrice() public {
        vm.startPrank(user1);
        vm.expectRevert();
        nft.setMintPrice(0.1 ether);
        vm.stopPrank();
    }

    function testPublicMint() public {
        vm.startPrank(owner);
        nft.setMintPrice(0.1 ether);
        vm.stopPrank();

        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        uint256 tokenId = nft.mintPublic{value: 0.1 ether}("ipfs://metadata1");
        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(1), user1);
        assertEq(address(nft).balance, 0.1 ether);
        vm.stopPrank();
    }

    function testPublicMintInsufficientFunds() public {
        vm.startPrank(owner);
        nft.setMintPrice(0.1 ether);
        vm.stopPrank();

        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vm.expectRevert("Insufficient funds to mint");
        nft.mintPublic{value: 0.05 ether}("ipfs://metadata1");
        vm.stopPrank();
    }

    function testPublicMintExcessFunds() public {
        vm.startPrank(owner);
        nft.setMintPrice(0.1 ether);
        vm.stopPrank();

        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        uint256 tokenId = nft.mintPublic{value: 0.2 ether}("ipfs://metadata1");
        assertEq(tokenId, 1);
        assertEq(address(nft).balance, 0.2 ether);
        vm.stopPrank();
    }

    function testMaxSupplyReached() public {
        vm.startPrank(owner);
        for (uint256 i = 0; i < 10; i++) {
            nft.mint(user1, string(abi.encodePacked("ipfs://metadata", i)));
        }
        vm.stopPrank();
    }
}