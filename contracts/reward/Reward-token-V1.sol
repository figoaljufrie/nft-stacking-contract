//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

// import "@openzeppelin/contracts/proxy/utils/Initializible.sol";

contract RewardTokenUpgradeable is
    UUPSUpgradeable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    // Max total supply (e.g., 10 million tokens)
    uint256 public constant MAX_SUPPLY = 10_000_000 * 10 ** 18;

    // Address allowed to mint (staking contract)
    address public stakingManager;

    event StakingManagerUpdated(
        address indexed oldManager,
        address indexed newManager
    );

    constructor() {
        // _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        address initialOwner
    ) public initializer {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __Ownable_init(initialOwner);
        __Pausable_init();
        // Initial mint to owner for liquidity or initial distribution
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }

    // Owner sets staking manager
    function setStakingManager(address _manager) external onlyOwner {
        require(_manager != address(0), "Invalid manager address");
        address oldManager = stakingManager;
        stakingManager = _manager;
        emit StakingManagerUpdated(oldManager, _manager);
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

    // Override _update to respect pause - FIXED: was whenPaused, now whenNotPaused
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._update(from, to, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
