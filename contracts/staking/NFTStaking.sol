// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.28;

//contract Name: /OOP in web-2 (class)
contract NFTStaking {
    //state-variable:

    //address = any eth wallet address. Can be owner, or user.
    address public owner; // contact-owner.
    //total staked of an NFT.
    uint256 public totalStaked; // total nft-staked of all users.

    //map address & uint 256 to get the users wallet's stake.
    mapping(address => uint256) public userStaked; // track each users staked.
    mapping(address => uint256) public stakeTimestamps;

    //events (listener / log / web-hook in web-2)

    //user staked log: (IN)
    event Staked(address indexed user, uint256 amount);
    //user un-staked log: (OUT)
    event Unstaked(address indexed user, uint256 amount);
    //reset time-stamp after reward claim.
    event RewardClaimed(address indexed user, uint256 reward);

    //the reason why staked and unstaked is seperated, because they have opposite actions. Seperating helps analytics & front-end listeners.
    constructor() {
        //msg.sender = wallet deploying the contract.
        //msg.sender = owner's wallet.
        owner = msg.sender;
    }

    //modifiers (equivalent of RBAC in web-2);
    /**its the same as:
    export default function onlyOwner() => {
    if (msg.sender !== owner) {
    return (" Not authorized)
    } next();
    **/
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Authorized");
        _; //underscore equals to next() in web-2.
    }

    //function A: business logics A.
    function stake(uint256 amount) public {
        //rules: amount must be more than 0, need to be positive. Same, if not bigger than 0, throw warning message.
        require(amount > 0, "Amount must be positive");
        /**
      msg.sender(owner's wallet) = Alice.
      userStaked[alice] = 0
      amount = 5
      alice's userStaked = 0 + 5 = 5 (new Alice User's Staked?)
       */
        userStaked[msg.sender] += amount;

        //total-staked = sum of all userStaked.
        //Alice have 5 User Staked
        //Bob has 2 User Staked
        //then, total Staked = 7.
        totalStaked += amount;
        stakeTimestamps[msg.sender] = block.timestamp;

        //broadcast to log? Broadcast user + amount entered?
        emit Staked(msg.sender, amount);

        /**
      note;
      User Staked = per individual
      Total Staked = Global, sum of all User Staked that exist.

      So every time there is a transaction, amount of user new staked will be incremented to the global stake.
      */
    }

    function unstake(uint256 amount) public {
        //user-stake nft must be larger than emount, if not, throw message.
        require(userStaked[msg.sender] >= amount, "Not enough staked");

        //If userStaked >= amount, userStaked - amount;
        userStaked[msg.sender] -= amount;

        //(global staked) - (userStake current transactions amount)
        totalStaked -= amount;

        //broadcast to log transaction unstaked?
        emit Unstaked(msg.sender, amount);
    }

    //check reward (placeholder);

    //address = user who made transaction?
    function calculateRewards(address user) public view returns (uint256) {
        //return userStaked after transaction, notify log user-staked amount after staking or unstaking.
        uint256 staked = userStaked[user];
        uint256 duration = block.timestamp - stakeTimestamps[user];

        uint256 dailyRewardRate = 1e16;
        uint256 reward = (staked * dailyRewardRate * duration) / 1 days;
        return reward;
    }

    function claimRewards() public {
        uint256 rewards = calculateRewards(msg.sender);
        require(rewards > 0, "No rewards yet");

        //reset timestamp after claiming.
        stakeTimestamps[msg.sender] = block.timestamp;

        //payout( in real contract, this is the token transfer phase);
        emit RewardClaimed(msg.sender, rewards);
    }

    function resetUserStake(address user) external onlyOwner {
        totalStaked -= userStaked[user];
        userStaked[user] = 0;
        stakeTimestamps[user] = 0;
    }
}
