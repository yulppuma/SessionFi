import { useAccount, useBalance } from 'wagmi'

export function useWallet() {
  const { address, isConnected } = useAccount()
  const { data: balance } = useBalance({ address })

  return {
    address,
    isConnected,
    balance,
  }
}
