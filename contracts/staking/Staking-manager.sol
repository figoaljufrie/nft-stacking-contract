//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract StakingManager is Ownable, ReentrancyGuardTransient {
    IERC721 public nftCollection; //NFT Collection that users staked.
    IERC20 public rewardToken; // ERC20 token used for rewards.
    uint256 public rewardRate; //Reward per NFT per second.
    bool public paused;

    //keeps track of which NFTs user has staked.
    struct StakeInfo {
        uint256[] tokenIds; //NFT currently staked.
        mapping(uint256 => uint256) tokenIndex; // index of NFT in tokenIds array
        uint256 lastClaim; // timestamp
        uint256 accumulatedReward; //checkpoint reward (avoid recalculating);
    }

    mapping(address => StakeInfo) private stakes;

    //for front-end to listens users actions (& update UI real-time)
    event Staked(address indexed user, uint256 indexed tokenId);
    event Withdrawn(address indexed user, uint256 indexed tokenId);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event Paused();
    event Unpaused();

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(
        address _nftCollection,
        address _rewardToken,
        uint256 _rewardRate,
        address initialOwner
    ) Ownable(initialOwner) ReentrancyGuardTransient() {
        require(_nftCollection != address(0), "Invalid NFT address");
        require(_rewardToken != address(0), "Invalid token address");
        nftCollection = IERC721(_nftCollection);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
    }

    //users can stake multiple NFTs at once.
    function stake(
        uint256[] calldata tokenIds
    ) external nonReentrant whenNotPaused {
        require(tokenIds.length > 0, "No tokens provided");
        StakeInfo storage userStake = stakes[msg.sender];
        //update pending reward (checkpoint of existing reward);
        _updateReward(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            //trnasfer NFT to the contract.
            nftCollection.transferFrom(msg.sender, address(this), tokenId);
            // updateTokenIds array & tokenIndex mapping for O(1)
            userStake.tokenIndex[tokenId] = userStake.tokenIds.length;
            userStake.tokenIds.push(tokenId);
            emit Staked(msg.sender, tokenId);
        }
        userStake.lastClaim = block.timestamp;
    }

    function withdraw(
        uint256[] calldata tokenIds
    ) external nonReentrant whenNotPaused {
        require(tokenIds.length > 0, "No tokens provided");
        //update pending reward.
        _updateReward(msg.sender);

        //check if user actually staked.
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            //if not, throw validation:
            require(_isTokenStaked(msg.sender, tokenId), "Token not staked");
            //remove token.
            _removeToken(msg.sender, tokenId);
            //transfer nft back to user.
            nftCollection.transferFrom(address(this), msg.sender, tokenId);
            //emit withdrawal status info:
            emit Withdrawn(msg.sender, tokenId);
        }
    }

    //claim rewards. Transfer accumulated reward to user.
    function claimRewards() external nonReentrant whenNotPaused {
        _updateReward(msg.sender); // ensure rewards are up-to-date
        StakeInfo storage userStake = stakes[msg.sender];
        uint256 reward = userStake.accumulatedReward;
        //validation: check if there are reward to claim.
        require(reward > 0, "No rewards available");
        //reset accumulated reward to zero.
        userStake.accumulatedReward = 0;

        // Try to pay from contract balance first
        uint256 balance = rewardToken.balanceOf(address(this));
        if (balance >= reward) {
            // Enough pre-funded tokens, transfer
            require(
                rewardToken.transfer(msg.sender, reward),
                "Transfer failed"
            );
        } else {
            // Not enough balance — attempt to mint (if rewardToken supports it)
            try IRewardToken(address(rewardToken)).mint(msg.sender, reward) {
                // Successfully minted directly to user
            } catch {
                // mint failed - revert with clear message
                revert("Insufficient reward balance and mint failed");
            }
        }

        emit RewardClaimed(msg.sender, reward);
    }

    function getUserStakeInfo(
        address user
    )
        external
        view
        returns (
            uint256[] memory tokens,
            uint256 lastClaim,
            uint256 accumulated
        )
    {
        StakeInfo storage s = stakes[user];
        return (s.tokenIds, s.lastClaim, s.accumulatedReward);
    }

    function getTokenIndex(
        address user,
        uint256 tokenId
    ) external view returns (uint256 index, bool exists) {
        StakeInfo storage s = stakes[user];
        uint256 idx = s.tokenIndex[tokenId];
        bool ok = (idx < s.tokenIds.length && s.tokenIds[idx] == tokenId);
        return (idx, ok);
    }

    //--------INTERNAL FUNCTION---------//

    //update logics whenever staking, withdrawing, or claiming rewards.
    //checkpoint; to avoid looping all the user's staked NFTs every time.
    function _updateReward(address user) internal {
        StakeInfo storage userStake = stakes[user];
        if (userStake.lastClaim == 0) {
            userStake.lastClaim = block.timestamp;
            return;
        }
        uint256 timeStaked = block.timestamp - userStake.lastClaim;
        uint256 stakedCount = userStake.tokenIds.length;
        if (timeStaked > 0 && stakedCount > 0) {
            userStake.accumulatedReward +=
                timeStaked *
                stakedCount *
                rewardRate;
        }
        userStake.lastClaim = block.timestamp;
    }

    function _isTokenStaked(
        address user,
        uint256 tokenId
    ) internal view returns (bool) {
        StakeInfo storage userStake = stakes[user];
        uint256 index = userStake.tokenIndex[tokenId];
        return
            index < userStake.tokenIds.length &&
            userStake.tokenIds[index] == tokenId;
    }

    //uses swap-pop with mapping ->O(1) removal.
    function _removeToken(address user, uint256 tokenId) internal {
        StakeInfo storage userStake = stakes[user];
        uint256 index = userStake.tokenIndex[tokenId];
        uint256 lastTokenId = userStake.tokenIds[userStake.tokenIds.length - 1];
        userStake.tokenIds[index] = lastTokenId;
        userStake.tokenIndex[lastTokenId] = index;
        userStake.tokenIds.pop();
        delete userStake.tokenIndex[tokenId];
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        uint256 oldRate = rewardRate;
        rewardRate = _rewardRate;
        emit RewardRateUpdated(oldRate, _rewardRate);
        // NOTE: This changes reward rate immediately for all pending rewards.
        // Consider updating all active stakers' rewards before changing rate
        // if you want to preserve their earnings at the old rate.
    }

    function setNFTCollection(address _nftCollection) external onlyOwner {
        require(_nftCollection != address(0), "Invalid NFT address");
        nftCollection = IERC721(_nftCollection);
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0), "Invalid token address");
        rewardToken = IERC20(_rewardToken);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        if (paused) emit Paused();
        else emit Unpaused();
    }

    function emergencyWithdraw(
        address to,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        // SECURITY: This function allows owner to withdraw user NFTs.
        // Only use for genuine emergencies (e.g., contract migration).
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (_isTokenStaked(to, tokenId)) {
                _removeToken(to, tokenId);
                nftCollection.transferFrom(address(this), to, tokenId);
            }
        }
    }

    function emergencyUnstake(
        uint256[] calldata tokenIds
    ) external whenNotPaused {
        // Update rewards before emergency unstake so user doesn't lose rewards
        _updateReward(msg.sender);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_isTokenStaked(msg.sender, tokenIds[i])) {
                _removeToken(msg.sender, tokenIds[i]);
                nftCollection.transferFrom(
                    address(this),
                    msg.sender,
                    tokenIds[i]
                );
                emit Withdrawn(msg.sender, tokenIds[i]);
            }
        }
    }

    function getStakedTokens(
        address user
    ) external view returns (uint256[] memory) {
        return stakes[user].tokenIds;
    }

    function pendingRewards(address user) external view returns (uint256) {
        StakeInfo storage userStake = stakes[user];
        if (userStake.lastClaim == 0) return 0;
        uint256 timeStaked = block.timestamp - userStake.lastClaim;
        return
            userStake.accumulatedReward +
            timeStaked *
            userStake.tokenIds.length *
            rewardRate;
    }

    function getFullStake(
        address user
    )
        external
        view
        returns (
            uint256[] memory tokenIds,
            uint256 lastClaim,
            uint256 accumulated,
            uint256 pending
        )
    {
        StakeInfo storage s = stakes[user];
        uint256 timeStaked = block.timestamp - s.lastClaim;
        uint256 pendingReward = timeStaked * s.tokenIds.length * rewardRate;
        return (s.tokenIds, s.lastClaim, s.accumulatedReward, pendingReward);
    }
}
