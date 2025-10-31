//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract TreasuryVault is
    OwnableUpgradeable,
    ReentrancyGuardTransientUpgradeable,
    UUPSUpgradeable
{
    IERC20 public rewardToken;
    bool public paused;

    event FundsDeposited(address indexed from, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event RewardSent(address indexed to, uint256 amount);
    event Paused();
    event Unpaused();

    modifier whenNotPaused() {
        require(!paused, "Vault is paused");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _rewardToken,
        address initialOwner
    ) public initializer {
        __Ownable_init(initialOwner);
        __ReentrancyGuardTransient_init();

        require(_rewardToken != address(0), "Invalid token address");
        rewardToken = IERC20(_rewardToken);
    }

    function depositFunds(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Invalid amount");
        require(
            rewardToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        emit FundsDeposited(msg.sender, amount);
    }

    function withdraw(
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        require(to != address(0), "Invalid Recipient");
        require(amount > 0, "Invalid amount");
        require(
            rewardToken.balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        require(rewardToken.transfer(to, amount), "Transfer failed");
        emit FundsWithdrawn(to, amount);
    }

    function sendReward(
        address to,
        uint256 amount
    ) external onlyOwner whenNotPaused nonReentrant {
        require(to != address(0), "Invalid Recipient");
        require(amount > 0, "invalid amount");
        require(
            rewardToken.balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        require(rewardToken.transfer(to, amount), "Transfer failed");
        emit RewardSent(to, amount);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function getBalance() external view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}
