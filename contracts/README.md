# SessionFi Smart Contracts

Solidity smart contracts for SessionFi - Scoped delegated execution for automated Web3 interactions.

## Quick Start

### Prerequisites
- Foundry (`foundryup`)
- Node.js 18+ (for running scripts)

### Setup

```bash
# Install Foundry dependencies
forge install

# Copy environment file and fill in your values
cp .env.example .env
# Edit .env with:
# - Your wallet's PRIVATE_KEY
# - Your Infura SEPOLIA_RPC_URL
# - Your Etherscan API Key
```

### Testing

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vv

# Run specific test
forge test -m testCreateSession

# With gas report
forge test --gas-report
```

### Deployment

```bash
# Deploy to Sepolia testnet
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast

# Deploy and verify on Etherscan
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

After deployment, save the contract addresses - you'll need them for the frontend.

## Contract Overview

### SessionFiWallet.sol
Core contract for session-based delegated execution.

**Key Functions:**
- `createSession()` - Create a new delegated session
- `executeSessionTransaction()` - Execute a transaction within session boundaries
- `revokeSession()` - Revoke an active session
- `getSession()` - Get session details
- `isSessionValid()` - Check if session is valid

### SessionManager.sol
Manages session metadata and permissions.

## Environment Variables

Copy `.env.example` to `.env` and fill in:

- `PRIVATE_KEY` - Your wallet's private key (from MetaMask)
- `SEPOLIA_RPC_URL` - RPC endpoint for Sepolia testnet
- `ETHERSCAN_API_KEY` - For contract verification

## Getting Test ETH

Visit https://sepoliafaucet.com and claim 1 Sepolia ETH

## Useful Commands

```bash
# Check contract size
forge build --sizes

# Format code
forge fmt

# Watch for changes
forge watch

# Get ABIs
forge inspect SessionFiWallet abi
```

## Documentation

See the main README.md for full documentation.
