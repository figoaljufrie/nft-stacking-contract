// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockRewardToken is ERC20 {
  constructor() ERC20("Mock Reward Token", "MRT") {}

  function mint(address to, uint256 amount) external {
    _mint(to, amount);
  }
}