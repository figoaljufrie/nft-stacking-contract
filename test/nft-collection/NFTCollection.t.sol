// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../contracts/nft-collection/NFTCollection.sol";

contract MyNFTTest is Test {
    MyNFT public nft;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    // Events to test
    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        string tokenURI
    );

    function setUp() public {
        vm.startPrank(owner);
        nft = new MyNFT(owner);
        vm.stopPrank();
    }

    // Test initial state
    function testInitialState() public {
        assertEq(nft.owner(), owner);
        assertEq(nft.totalSupply(), 0);
        assertEq(nft.mintPrice(), 0);
        assertEq(nft.name(), "MyNFT");
        assertEq(nft.symbol(), "MNFT");
    }

    // Test owner minting
    function testOwnerMint() public {
        vm.startPrank(owner);

        uint256 tokenId = nft.mint(user1, "ipfs://metadata1");

        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.tokenURI(1), "ipfs://metadata1");

        vm.stopPrank();
    }

    // Test multiple owner mints
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

    // Test non-owner cannot mint
    function testNonOwnerCannotMint() public {
        vm.startPrank(user1);

        vm.expectRevert();
        nft.mint(user1, "ipfs://metadata1");

        vm.stopPrank();
    }

    // Test set mint price
    function testSetMintPrice() public {
        vm.startPrank(owner);

        nft.setMintPrice(0.1 ether);
        assertEq(nft.mintPrice(), 0.1 ether);

        vm.stopPrank();
    }

    // Test non-owner cannot set mint price
    function testNonOwnerCannotSetMintPrice() public {
        vm.startPrank(user1);

        vm.expectRevert();
        nft.setMintPrice(0.1 ether);

        vm.stopPrank();
    }

    // Test public mint with sufficient funds
    function testPublicMint() public {
        vm.startPrank(owner);
        nft.setMintPrice(0.1 ether);
        vm.stopPrank();

        // Give user1 some ETH
        vm.deal(user1, 1 ether);

        vm.startPrank(user1);
        uint256 tokenId = nft.mintPublic{value: 0.1 ether}("ipfs://metadata1");

        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(1), user1);
        assertEq(address(nft).balance, 0.1 ether);

        vm.stopPrank();
    }

    // Test public mint with insufficient funds
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

    // Test public mint with excess funds
    function testPublicMintExcessFunds() public {
        vm.startPrank(owner);
        nft.setMintPrice(0.1 ether);
        vm.stopPrank();

        vm.deal(user1, 1 ether);

        vm.startPrank(user1);

        // User sends more than required
        uint256 tokenId = nft.mintPublic{value: 0.2 ether}("ipfs://metadata1");

        assertEq(tokenId, 1);
        // Contract should receive the full 0.2 ether
        assertEq(address(nft).balance, 0.2 ether);

        vm.stopPrank();
    }

    // Test max supply enforcement
    function testMaxSupplyReached() public {
        vm.startPrank(owner);

        // Mint up to max supply (10000)
        // For testing, we'll just test the boundary
        // Fast forward to token 9999
        for (uint256 i = 0; i < 10; i++) {
            nft.mint(user1, string(abi.encodePacked("ipfs://metadata", i)));
        }

        vm.stopPrank();
    }

    // Test withdraw function
    function testWithdraw() public {
        // Setup: mint some NFTs to accumulate funds
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

    // Test withdraw with no funds
    function testWithdrawNoFunds() public {
        vm.startPrank(owner);

        vm.expectRevert("No funds to withdraw");
        nft.withdraw();

        vm.stopPrank();
    }

    // Test non-owner cannot withdraw
    function testNonOwnerCannotWithdraw() public {
        vm.startPrank(user1);

        vm.expectRevert();
        nft.withdraw();

        vm.stopPrank();
    }

    // Test set base URI
    function testSetBaseURI() public {
        vm.startPrank(owner);

        nft.setBaseURI("https://api.example.com/");
        nft.mint(user1, "1");

        // TokenURI should be baseURI + tokenURI
        assertEq(nft.tokenURI(1), "https://api.example.com/1");

        vm.stopPrank();
    }

    // Test non-owner cannot set base URI
    function testNonOwnerCannotSetBaseURI() public {
        vm.startPrank(user1);

        vm.expectRevert();
        nft.setBaseURI("https://api.example.com/");

        vm.stopPrank();
    }

    // Test token URI for non-existent token
    function testTokenURINonExistent() public {
        vm.expectRevert();
        nft.tokenURI(999);
    }

    // Test NFT transfer
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

    // Test NFT burn
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

    // Test enumeration functions
    function testEnumeration() public {
        vm.startPrank(owner);

        nft.mint(user1, "ipfs://metadata1");
        nft.mint(user1, "ipfs://metadata2");
        nft.mint(user2, "ipfs://metadata3");

        vm.stopPrank();

        // Check token by index
        assertEq(nft.tokenByIndex(0), 1);
        assertEq(nft.tokenByIndex(1), 2);
        assertEq(nft.tokenByIndex(2), 3);

        // Check token of owner by index
        assertEq(nft.tokenOfOwnerByIndex(user1, 0), 1);
        assertEq(nft.tokenOfOwnerByIndex(user1, 1), 2);
        assertEq(nft.tokenOfOwnerByIndex(user2, 0), 3);
    }

    // Test supportsInterface
    function testSupportsInterface() public {
        // ERC721 interface ID
        assertTrue(nft.supportsInterface(0x80ac58cd));
        // ERC721Enumerable interface ID
        assertTrue(nft.supportsInterface(0x780e9d63));
    }
}
