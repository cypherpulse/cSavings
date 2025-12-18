// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract

// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Custom errors
error cSavings__ZeroAmount();
error cSavings__InsufficientBalance();
error cSavings__TransferFailed();
error cSavings__NotOwner();

/// @title cSavings - Simple Savings Vault for cUSD on Celo
/// @notice A pooled savings vault for cUSD (ERC-20) on the Celo network.
/// Users can deposit cUSD, accrue rewards at a fixed rate, and withdraw principal plus rewards.
/// This contract is for educational purposes and follows Cyfrin-style secure patterns.
/// Deployment target: Celo testnet or mainnet; network config handled via Foundry (foundry.toml, forge script with RPC URL and chainId).
contract cSavings {
    // Type declarations
    // (none)

    // State variables
    IERC20 public immutable I_CUSD;
    address private immutable I_OWNER;
    uint256 private sTotalDeposits;
    uint256 public rewardRate; // rewards per second for the entire pool
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private sBalances; // user principal

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event RewardsFunded(uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    // Functions

    function _onlyOwner() internal view {
        if (msg.sender != I_OWNER) revert cSavings__NotOwner();
    }

    function _updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    // constructor
    constructor(address cusd, uint256 initialRewardRate) {
        I_CUSD = IERC20(cusd);
        I_OWNER = msg.sender;
        rewardRate = initialRewardRate;
        lastUpdateTime = block.timestamp;
    }

    // external
    function deposit(uint256 amount) external updateReward(msg.sender) {
        if (amount == 0) revert cSavings__ZeroAmount();
        sBalances[msg.sender] += amount;
        sTotalDeposits += amount;
        bool success = I_CUSD.transferFrom(msg.sender, address(this), amount);
        if (!success) revert cSavings__TransferFailed();
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        if (amount == 0) revert cSavings__ZeroAmount();
        if (amount > sBalances[msg.sender]) revert cSavings__InsufficientBalance();
        sBalances[msg.sender] -= amount;
        sTotalDeposits -= amount;
        bool success = I_CUSD.transfer(msg.sender, amount);
        if (!success) revert cSavings__TransferFailed();
        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            bool success = I_CUSD.transfer(msg.sender, reward);
            if (!success) revert cSavings__TransferFailed();
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        uint256 balance = sBalances[msg.sender];
        withdraw(balance);
        claimRewards();
    }

    function setRewardRate(uint256 newRate) external onlyOwner updateReward(address(0)) {
        uint256 oldRate = rewardRate;
        rewardRate = newRate;
        emit RewardRateUpdated(oldRate, newRate);
    }

    function fundRewards(uint256 amount) external onlyOwner {
        if (amount == 0) revert cSavings__ZeroAmount();
        bool success = I_CUSD.transferFrom(msg.sender, address(this), amount);
        if (!success) revert cSavings__TransferFailed();
        emit RewardsFunded(amount);
    }

    // view & pure functions
    function totalDeposits() external view returns (uint256) {
        return sTotalDeposits;
    }

    function balanceOf(address account) external view returns (uint256) {
        return sBalances[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (sTotalDeposits == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (rewardRate * (block.timestamp - lastUpdateTime) * 1e18) / sTotalDeposits;
    }

    function earned(address account) public view returns (uint256) {
        return (sBalances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
    }

    function owner() external view returns (address) {
        return I_OWNER;
    }
}