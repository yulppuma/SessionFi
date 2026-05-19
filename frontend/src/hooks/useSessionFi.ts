import { useState, useCallback, useEffect } from 'react';
import { useAccount, usePublicClient, useWalletClient } from 'wagmi';
import { CONTRACT_ADDRESSES } from '../config/wagmi';

export interface Session {
  id: string;
  owner: string;
  sessionKey: string;
  targetContract: string;
  functionSelector: string;
  maxSpend: bigint;
  spentAmount: bigint;
  token: string;
  createdAt: Date;
  expiresAt: Date;
  active: boolean;
  nonce: number;
  maxNonce: number;
}

export interface Stats {
  totalSessions: number;
  activeSessions: number;
  totalSpent: bigint;
}

// Simplified ABI for basic interactions
const SESSION_FI_ABI = [
  {
    inputs: [
      { name: 'sessionKey', type: 'address' },
      { name: 'allowedTarget', type: 'address' },
      { name: 'allowedSelector', type: 'bytes4' },
      { name: 'allowedToken', type: 'address' },
      { name: 'maxAmount', type: 'uint256' },
      { name: 'duration', type: 'uint256' },
      { name: 'maxNonce', type: 'uint256' },
    ],
    name: 'createSession',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'sessionId', type: 'uint256' }],
    name: 'revokeSession',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'user', type: 'address' }],
    name: 'getUserSessions',
    outputs: [{ name: '', type: 'uint256[]' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'getStats',
    outputs: [
      { name: '', type: 'uint256' },
      { name: '', type: 'uint256' },
    ],
    stateMutability: 'view',
    type: 'function',
  },
] as const;

export const useSessionFi = () => {
  const { address, isConnected } = useAccount();
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();

  const [userSessions, setUserSessions] = useState<Session[]>([]);
  const [stats, setStats] = useState<Stats>({ totalSessions: 0, activeSessions: 0, totalSpent: BigInt(0) });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    if (!address || !publicClient || !CONTRACT_ADDRESSES.sessionFiWallet) return;

    try {
      setIsLoading(true);
      setError(null);

      // Fetch basic stats
      // Note: Full implementation would fetch all session details
      setUserSessions([]);
      setStats({ totalSessions: 0, activeSessions: 0, totalSpent: BigInt(0) });
    } catch (err) {
      console.error('Failed to fetch sessions:', err);
      setError(err instanceof Error ? err.message : 'Failed to load sessions');
    } finally {
      setIsLoading(false);
    }
  }, [address, publicClient]);

  useEffect(() => {
    if (isConnected && address) {
      refresh();
      const interval = setInterval(refresh, 30000);
      return () => clearInterval(interval);
    }
  }, [isConnected, address, refresh]);

  const createSession = useCallback(
    async (config: any) => {
      if (!address || !walletClient) throw new Error('Wallet not connected');

      try {
        setError(null);

        const duration = config.duration * 86400;
        const maxSpend = BigInt(config.maxSpend) * BigInt(10 ** 6);

        // Contract write would go here
        console.log('Creating session with config:', config);
        await refresh();
        return '0x0';
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to create session';
        setError(message);
        throw err;
      }
    },
    [address, walletClient, refresh]
  );

  const revokeSession = useCallback(
    async (sessionId: string) => {
      if (!walletClient) throw new Error('Wallet not connected');

      try {
        setError(null);
        // Contract write would go here
        await refresh();
        return '0x0';
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to revoke session';
        setError(message);
        throw err;
      }
    },
    [walletClient, refresh]
  );

  return {
    userSessions,
    stats,
    isLoading,
    error,
    refresh,
    createSession,
    revokeSession,
  };
};
