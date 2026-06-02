import { useContract } from './useContract'
import { SESSION_FI_ABI } from '../utils/contracts'

export function useSessionFi() {
  const { contract, isLoading } = useContract(
    process.env.VITE_SESSION_FI_CONTRACT || '',
    SESSION_FI_ABI
  )

  const createSession = async (sessionKey: string, targetContract: string, selector: string, token: string, maxAmount: string, duration: number, maxNonce: number) => {
    if (!contract) throw new Error('Contract not loaded')
    // Session creation logic
  }

  const executeSession = async (sessionId: string, amount: string) => {
    if (!contract) throw new Error('Contract not loaded')
    // Execution logic
  }

  return {
    createSession,
    executeSession,
    isLoading,
  }
}
