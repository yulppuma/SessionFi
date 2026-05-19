import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';
import { http } from 'wagmi';

const projectId = import.meta.env.VITE_WALLET_CONNECT_PROJECT_ID || '';

if (!projectId) {
  console.warn('VITE_WALLET_CONNECT_PROJECT_ID is not set');
}

export const wagmiConfig = getDefaultConfig({
  appName: 'SessionFi',
  projectId: projectId,
  chains: [sepolia],
  transports: {
    [sepolia.id]: http(
      `https://sepolia.infura.io/v3/${import.meta.env.VITE_INFURA_KEY || ''}`
    ),
  },
  ssr: false,
});

export const CHAIN_CONFIG = {
  id: sepolia.id,
  name: sepolia.name,
  rpcUrl: `https://sepolia.infura.io/v3/${import.meta.env.VITE_INFURA_KEY || ''}`,
  blockExplorer: 'https://sepolia.etherscan.io',
};

export const CONTRACT_ADDRESSES = {
  sessionFiWallet: import.meta.env.VITE_SESSION_FI_CONTRACT || '',
  sessionManager: import.meta.env.VITE_SESSION_MANAGER_CONTRACT || '',
  usdc: import.meta.env.VITE_USDC_ADDRESS || '0x',
};

if (!CONTRACT_ADDRESSES.sessionFiWallet) {
  console.warn('VITE_SESSION_FI_CONTRACT environment variable not set');
}
