//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../../contracts/nft-collection/NFTCollection.sol";

contract MyNFTTest is Test {
    MyNFT nft;

    address owner = address(this);
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        nft = new MyNFT(owner);
    }

    function testNameAndSymbol() public view {
        assertEq(nft.name(), "MyNFT");
        assertEq(nft.symbol(), "MNFT");
    }

    function testMintByOwner() public {
        nft.mint(alice, "ipfs://token-1.json");
        string memory uri = nft.tokenURI(1);
        assertEq(uri, "ipfs://token-1.json");
    }

    function testFailMintByNonOwnerRevert() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                alice
            )
        );
        nft.mint(alice, "ipfs://unauthorized.json");
    }

    function testTokenIdIncrement() public {
        nft.mint(alice, "ipfs://1.json");
        nft.mint(bob, "ipfs://2.json");

        string memory uri1 = nft.tokenURI(1);
        string memory uri2 = nft.tokenURI(2);

        assertEq(uri1, "ipfs://1.json");
        assertEq(uri2, "ipfs://2.json");
    }

    function testBalanceOfAfterMint() public {
        nft.mint(alice, "ipfs://a.json");
        nft.mint(bob, "ipfs://b.json");
        uint256 aliceBalance = nft.balanceOf(alice);
        uint256 bobBalance = nft.balanceOf(bob);
        assertEq(aliceBalance, 1);
        assertEq(bobBalance, 1);
    }
}
