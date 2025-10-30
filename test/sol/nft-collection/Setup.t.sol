// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../../contracts/nft-collection/NFTCollection.sol";

contract MyNFTSetupTest is Test {
    MyNFT public nft;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        nft = new MyNFT(owner);
        vm.stopPrank();
    }

    function testInitialState() public view {
        assertEq(nft.owner(), owner);
        assertEq(nft.totalSupply(), 0);
        assertEq(nft.mintPrice(), 0);
        assertEq(nft.name(), "MyNFT");
        assertEq(nft.symbol(), "MNFT");
    }
}