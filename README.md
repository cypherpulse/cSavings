# cSavings - Simple Savings Vault for cUSD on Celo

[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FF6B35)](https://book.getfoundry.sh/)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-blue)](https://soliditylang.org/)
[![Celo](https://img.shields.io/badge/Network-Celo-green)](https://celo.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A secure, battle-tested pooled savings vault smart contract for cUSD (Celo Dollar) on the Celo blockchain. Built with industry-standard security patterns and best practices for Ethereum development.

![cSavings Architecture](public/cSaving.PNG)

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Deployment](#deployment)
- [API Documentation](#api-documentation)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Overview

cSavings is an educational yet production-ready smart contract that implements a simple savings vault for cUSD on the Celo network. Users can deposit cUSD tokens and earn rewards over time at a fixed rate proportional to their share of the total deposits. The contract demonstrates advanced Solidity patterns including:

- Reward-per-token accounting
- Owner-controlled parameters
- Secure ERC-20 interactions
- Comprehensive testing suite
- Gas-optimized modifiers

This project serves as both a learning resource for blockchain development and a foundation for more complex DeFi protocols.

## Architecture

### System Components

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│     Users       │────│   cSavings       │────│     cUSD        │
│                 │    │   Contract       │    │   Token         │
│ • Deposit cUSD  │    │                  │    │                 │
│ • Withdraw      │    │ • State Storage  │    │ • ERC-20        │
│ • Claim Rewards │    │ • Reward Logic   │    │ • Transfer      │
└─────────────────┘    │ • Access Control │    └─────────────────┘
                       └──────────────────┘            │
                              │                        │
                              ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │     Owner         │    │   Reward Pool   │
                       │                   │    │                 │
                       │ • Set Reward Rate│    │ • Funded by     │
                       │ • Fund Rewards   │    │   Owner          │
                       └──────────────────┘    └─────────────────┘
```

### Reward Mechanism

The contract uses a standard "reward-per-token" accounting system:

1. **Global State**: Tracks total deposits and cumulative rewards per token
2. **User Accounting**: Each user has their own reward checkpoint
3. **Reward Calculation**: `earned = balance × (rewardPerToken - userRewardPerTokenPaid) + pendingRewards`
4. **Time-Based Accrual**: Rewards accrue continuously based on `rewardRate × timeElapsed ÷ totalDeposits`

### Contract Structure

```
cSavings.sol
├── State Variables
│   ├── Immutable: I_CUSD, I_OWNER
│   ├── Mutable: sTotalDeposits, rewardRate, rewardPerTokenStored
│   └── Mappings: sBalances, userRewardPerTokenPaid, rewards
├── Modifiers
│   ├── onlyOwner (wrapped for gas optimization)
│   └── updateReward (reward accounting)
├── Functions
│   ├── External: deposit, withdraw, claimRewards, exit
│   ├── Owner: setRewardRate, fundRewards
│   └── View: totalDeposits, balanceOf, rewardPerToken, earned, owner
└── Events & Errors
    ├── Events: Deposited, Withdrawn, RewardPaid, RewardRateUpdated, RewardsFunded
    └── Custom Errors: ZeroAmount, InsufficientBalance, TransferFailed, NotOwner
```

## Features

### Core Functionality
- **Deposit**: Users can deposit cUSD and start earning rewards immediately
- **Withdraw**: Partial or full withdrawal of principal
- **Claim Rewards**: Separate claiming of accrued rewards
- **Exit**: Convenience function to withdraw all and claim rewards

### Administrative Features
- **Reward Rate Management**: Owner can adjust the reward rate
- **Reward Funding**: Owner can add cUSD to the reward pool
- **Access Control**: Only owner can perform administrative actions

### Security Features
- **Checks-Effects-Interactions**: Proper ERC-20 transfer ordering
- **Custom Errors**: Gas-efficient error handling
- **Immutable State**: Critical addresses set at deployment
- **Wrapped Modifiers**: Gas optimization for repeated modifier usage

### Developer Experience
- **Comprehensive Tests**: 12 test cases covering all scenarios
- **NatSpec Documentation**: Complete contract documentation
- **Forge Integration**: Full Foundry toolkit support
- **Environment Configuration**: Flexible deployment with .env support

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (latest version)
- [Git](https://git-scm.com/downloads)
- A Celo wallet with testnet/mainnet funds
- Node.js (optional, for additional tooling)

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd cSaving
   ```

2. **Install dependencies**
   ```bash
   forge install
   ```

3. **Set up environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Build the project**
   ```bash
   forge build
   ```

## Usage

### Local Development

1. **Start local node**
   ```bash
   anvil
   ```

2. **Run tests**
   ```bash
   forge test
   ```

3. **Get test coverage**
   ```bash
   forge coverage
   ```

### Interacting with Deployed Contract

```solidity
// Deposit cUSD
cSavings.deposit(100 * 10**18); // Deposit 100 cUSD

// Check balance and rewards
uint256 balance = cSavings.balanceOf(userAddress);
uint256 earned = cSavings.earned(userAddress);

// Withdraw
cSavings.withdraw(50 * 10**18); // Withdraw 50 cUSD

// Claim rewards
cSavings.claimRewards();
```

### Owner Operations

```solidity
// Set new reward rate (owner only)
cSavings.setRewardRate(2000000000000000); // 0.002 cUSD/second

// Fund reward pool (owner only)
cSavings.fundRewards(1000 * 10**18); // Add 1000 cUSD to rewards
```

## Testing

The project includes comprehensive tests covering:

- Deposit and withdrawal functionality
- Reward accrual over time
- Multi-user scenarios
- Administrative functions
- Edge cases and error conditions

```bash
# Run all tests
forge test

# Run with verbosity
forge test -v

# Run specific test
forge test --match-test testDeposit

# Run with gas reporting
forge test --gas-report
```

### Test Coverage

```bash
forge coverage --report lcov
# View coverage report in HTML format
```

## Deployment

### Testnet Deployment (Celo Sepolia)

1. **Configure environment**
   ```bash
   # .env
   CUSD_ADDRESS=0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1
   INITIAL_REWARD_RATE=1000000000000000
   ```

2. **Deploy**
   ```bash
   forge script script/DeploycSavings.s.sol \
     --rpc-url $CELO_SEPOLIA_RPC_URL \
     --account defaultKey \
     --broadcast
   ```

### Mainnet Deployment (Celo Mainnet)

1. **Update configuration**
   ```bash
   # .env
   CUSD_ADDRESS=0x765DE816845861e75A25fCA122bb6898B8B1282a0
   INITIAL_REWARD_RATE=1000000000000000
   ```

2. **Deploy**
   ```bash
   forge script script/DeploycSavings.s.sol \
     --rpc-url $CELO_MAINNET_RPC_URL \
     --account defaultKey \
     --broadcast
   ```

## API Documentation

### Public Functions

#### `deposit(uint256 amount)`
Deposits cUSD into the vault and starts earning rewards.

**Parameters:**
- `amount`: Amount of cUSD to deposit (in wei)

**Events:** `Deposited(msg.sender, amount)`

#### `withdraw(uint256 amount)`
Withdraws principal cUSD from the vault.

**Parameters:**
- `amount`: Amount of cUSD to withdraw

**Events:** `Withdrawn(msg.sender, amount)`

#### `claimRewards()`
Claims accrued rewards without withdrawing principal.

**Events:** `RewardPaid(msg.sender, reward)`

#### `exit()`
Withdraws all principal and claims all rewards.

### View Functions

#### `totalDeposits() returns (uint256)`
Returns total cUSD deposited in the vault.

#### `balanceOf(address account) returns (uint256)`
Returns the principal balance of an account.

#### `earned(address account) returns (uint256)`
Returns the total rewards earned by an account.

#### `rewardPerToken() returns (uint256)`
Returns the current reward per token rate.

### Owner Functions

#### `setRewardRate(uint256 newRate)`
Updates the reward rate (owner only).

**Events:** `RewardRateUpdated(oldRate, newRate)`

#### `fundRewards(uint256 amount)`
Adds cUSD to the reward pool (owner only).

**Events:** `RewardsFunded(amount)`

## Security

This contract has been developed following industry best practices:

- **Audited Patterns**: Uses proven reward accounting mechanisms
- **Input Validation**: All external functions validate inputs
- **Access Control**: Owner-only functions protected
- **ERC-20 Safety**: Proper transfer checks and ordering
- **Test Coverage**: Comprehensive test suite with edge cases

### Known Limitations
- Single asset (cUSD only)
- Fixed reward rate (no dynamic adjustments)
- No early withdrawal penalties
- Owner has significant control (trust assumption)

### Security Considerations
- Monitor reward pool funding
- Regular security audits recommended for production use
- Consider multi-sig ownership for mainnet deployment

## Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Write tests** for new functionality
4. **Ensure all tests pass**
   ```bash
   forge test
   ```
5. **Follow the coding style**
   - Follow established Solidity best practices
   - Add NatSpec documentation
   - Include custom errors
6. **Submit a pull request**

### Development Setup

```bash
# Install dependencies
forge install

# Run tests in watch mode
forge test --watch

# Format code
forge fmt

# Lint code
forge lint
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

- **Project Maintainer**: [Your Name]
- **Email**: [your.email@example.com]
- **GitHub**: [https://github.com/yourusername/cSaving]
- **Discord**: [Join our community]

---

*Built with ❤️ for the Celo ecosystem. Learn, build, and contribute to decentralized finance.*
