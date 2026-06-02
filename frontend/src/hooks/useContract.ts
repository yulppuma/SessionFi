import { useEffect, useState } from 'react'
import { usePublicClient } from 'wagmi'

export function useContract(address: string, abi: any) {
  const client = usePublicClient()
  const [contract, setContract] = useState<any>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    if (!address || !client) {
      setIsLoading(false)
      return
    }

    setContract({ address, abi, client })
    setIsLoading(false)
  }, [address, abi, client])

  return { contract, isLoading }
}
