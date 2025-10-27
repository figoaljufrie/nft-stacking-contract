// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract RewardToken is ERC20, ERC20Burnable, Ownable, Pausable {
    // Max total supply (e.g., 10 million tokens)
    uint256 public constant MAX_SUPPLY = 10_000_000 * 10 ** 18;

    // Address allowed to mint (staking contract)
    address public stakingManager;

    constructor(
        string memory name,
        string memory symbol,
        address initialOwner
    ) ERC20(name, symbol) Ownable(initialOwner) {
        // Initial mint to owner for liquidity or initial distribution
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }

    // Owner sets staking manager
    function setStakingManager(address _manager) external onlyOwner {
        stakingManager = _manager;
    }

    // Mint function callable only by stakingManager
    function mint(address to, uint256 amount) external whenNotPaused {
        require(msg.sender == stakingManager, "Not Authorized");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
    }

    // Pause contract (owner only)
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause contract (owner only)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Override _update to respect pause
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override whenPaused {
        super._update(from, to, amount);
    }
}
