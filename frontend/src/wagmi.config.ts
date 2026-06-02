import { getDefaultConfig } from '@rainbow-me/rainbowkit'
import { sepolia } from 'wagmi/chains'

export const config = getDefaultConfig({
  appName: 'SessionFi',
  projectId: import.meta.env.VITE_WALLET_CONNECT_PROJECT_ID || 'default-project-id',
  chains: [sepolia],
  ssr: false,
})
