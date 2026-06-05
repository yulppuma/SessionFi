import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { SESSION_FI_ABI } from '../utils/contracts'

export function useSessionFi() {
  const contractAddress = import.meta.env.VITE_SESSION_FI_CONTRACT as `0x${string}`
  
  const { writeContract, data: hash, isPending, error } = useWriteContract()
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  })

  const createSession = async (
    sessionKey: string,
    targetContract: string,
    selector: string,
    token: string,
    maxAmount: string,
    duration: number,
    maxNonce: number
  ) => {
    try {
      writeContract({
        address: contractAddress,
        abi: SESSION_FI_ABI,
        functionName: 'createSession',
        args: [
          sessionKey as `0x${string}`,
          targetContract as `0x${string}`,
          selector as `0x${string}`,
          token as `0x${string}`,
          BigInt(maxAmount),
          BigInt(duration),
          BigInt(maxNonce),
        ],
      })
    } catch (err) {
      console.error('Error creating session:', err)
      throw err
    }
  }

  const executeSession = async (
    sessionId: string,
    target: string,
    data: string,
    amount: string
  ) => {
    try {
      writeContract({
        address: contractAddress,
        abi: SESSION_FI_ABI,
        functionName: 'executeSessionTransaction',
        args: [
          BigInt(sessionId),
          target as `0x${string}`,
          data as `0x${string}`,
          BigInt(amount),
        ],
        value: amount === '0' ? BigInt(0) : BigInt(amount),
      })
    } catch (err) {
      console.error('Error executing session:', err)
      throw err
    }
  }

  return {
    createSession,
    executeSession,
    isLoading: isPending,
    isConfirming,
    isSuccess,
    error,
    hash,
  }
}