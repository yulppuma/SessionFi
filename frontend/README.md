# SessionFi Frontend

React + Vite + TypeScript frontend for SessionFi - Scoped delegated execution for automated Web3 interactions.

## Quick Start

### Prerequisites
- Node.js 18+ 
- pnpm (or npm)

### Setup

```bash
# Install dependencies
pnpm install
# or: npm install

# Copy environment file and fill in your values
cp .env.example .env.local

# Edit .env.local with:
# - Your VITE_WALLET_CONNECT_PROJECT_ID
# - Your VITE_INFURA_KEY
# - Your VITE_SESSION_FI_CONTRACT address from deployment
```

### Development

```bash
# Start development server
pnpm dev

# Server runs on http://localhost:5173
```

### Building

```bash
# Build for production
pnpm build

# Preview production build
pnpm preview
```

### Quality Checks

```bash
# Type checking
pnpm type-check

# Linting
pnpm lint

# Format code
pnpm format
```

## Environment Variables

Copy `.env.example` to `.env.local` and fill in:

- `VITE_WALLET_CONNECT_PROJECT_ID` - From https://cloud.walletconnect.com
- `VITE_INFURA_KEY` - From https://infura.io
- `VITE_SESSION_FI_CONTRACT` - Deployed SessionFiWallet contract address

## Project Structure

```
src/
├── components/        # React components
│   ├── Header.tsx
│   └── Footer.tsx
├── pages/            # Page components
│   ├── Dashboard.tsx
│   ├── CreateSession.tsx
│   ├── SessionDetail.tsx
│   └── Settings.tsx
├── hooks/            # Custom React hooks
│   └── useSessionFi.ts
├── config/           # Configuration
│   └── wagmi.ts
├── styles/           # CSS styles
│   └── App.css
├── App.tsx           # Root component
└── main.tsx          # Entry point
```

## Key Dependencies

- **React 18** - UI library
- **React Router** - Navigation
- **Wagmi** - Ethereum hooks
- **Rainbow Kit** - Wallet connection
- **Vite** - Build tool
- **TypeScript** - Type safety

## Available Pages

- `/` - Dashboard with session management
- `/create` - Create new session
- `/session/:id` - Session details
- `/settings` - Settings and information

## Features

- 🔐 Secure wallet connection (MetaMask, Rainbow, WalletConnect)
- 📋 Session dashboard with filtering
- ✨ Create and manage delegated sessions
- 📊 Session statistics and analytics
- 🎨 Dark theme UI with gradient styling

## Wallet Integration

The app uses RainbowKit for wallet connection and supports:
- MetaMask
- Rainbow Wallet
- WalletConnect
- Coinbase Wallet
- And more...

## Network

Currently configured for **Sepolia Testnet**. To use on a different network, update `src/config/wagmi.ts`.

## Documentation

See the main `README.md` for full project documentation.

## Troubleshooting

### "Module not found"
```bash
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

### "VITE_SESSION_FI_CONTRACT is not set"
Make sure you've:
1. Deployed the smart contracts
2. Added the contract address to `.env.local`

### Wallet won't connect
- Ensure MetaMask or another Web3 wallet is installed
- Check that you have Sepolia testnet added
- Refresh the page

## Support

- GitHub: https://github.com/sessionfi/sessionfi
- Discord: https://discord.gg/sessionfi
- Email: support@sessionfi.dev
