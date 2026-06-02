import { formatEther } from 'ethers'

export function formatAddress(address: string) {
  return address.slice(0, 6) + '...' + address.slice(-4)
}

export function formatAmount(amount: string, decimals: number = 18) {
  try {
    return formatEther(BigInt(amount))
  } catch {
    return '0'
  }
}

export function formatDate(timestamp: number) {
  return new Date(timestamp * 1000).toLocaleDateString()
}
