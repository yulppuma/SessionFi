import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useWriteContract } from 'wagmi'
import { SESSION_FI_ABI } from '../utils/contracts'

export default function CreateSession() {
  const navigate = useNavigate()
  const contractAddress = import.meta.env.VITE_SESSION_FI_CONTRACT as `0x${string}`
  const { writeContract, isPending, error } = useWriteContract()
  
  const [formData, setFormData] = useState({
    sessionKey: '',
    targetContract: '',
    functionSelector: '',
    token: '',
    maxAmount: '',
    duration: '',
    maxNonce: '',
  })

  const [feedback, setFeedback] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()

    try {
      setFeedback('')

      // Validate
      if (!formData.sessionKey || !formData.targetContract || !formData.functionSelector || !formData.token || !formData.maxAmount || !formData.duration || !formData.maxNonce) {
        setFeedback('❌ All fields are required')
        return
      }

      writeContract({
        address: contractAddress,
        abi: SESSION_FI_ABI,
        functionName: 'createSession',
        args: [
          formData.sessionKey as `0x${string}`,
          formData.targetContract as `0x${string}`,
          formData.functionSelector as `0x${string}`,
          formData.token as `0x${string}`,
          BigInt(formData.maxAmount),
          BigInt(parseInt(formData.duration) * 86400),
          BigInt(parseInt(formData.maxNonce)),
        ],
      })

      setFeedback('⏳ Check your wallet to approve the transaction...')
    } catch (err) {
      setFeedback(`❌ Error: ${err instanceof Error ? err.message : 'Unknown error'}`)
    }
  }

  return (
    <div className="create-session">
      <h2>Create New Session</h2>
      
      {feedback && <div className="feedback">{feedback}</div>}
      {error && <div className="feedback error">❌ {error.message}</div>}
      
      <form onSubmit={handleSubmit} className="session-form">
        <div className="form-group">
          <label>Session Key Address *</label>
          <small>The address that will be authorized to execute transactions (e.g., AI bot, another wallet, or contract)</small>
          <input 
            type="text" 
            placeholder="0x..."
            value={formData.sessionKey}
            onChange={(e) => setFormData({...formData, sessionKey: e.target.value})}
            disabled={isPending}
          />
        </div>

        <div className="form-group">
          <label>Target Contract *</label>
          <small>The contract this session can interact with (e.g., Uniswap Router, USDC token, etc.)</small>
          <input 
            type="text" 
            placeholder="0x..."
            value={formData.targetContract}
            onChange={(e) => setFormData({...formData, targetContract: e.target.value})}
            disabled={isPending}
          />
        </div>

        <div className="form-group">
          <label>Function Selector *</label>
          <small>4-byte function selector (e.g., 0x7ff36ab5 for swap, 0xa9059cbb for transfer). Get from Etherscan contract page.</small>
          <input 
            type="text" 
            placeholder="0x..."
            value={formData.functionSelector}
            onChange={(e) => setFormData({...formData, functionSelector: e.target.value})}
            disabled={isPending}
          />
        </div>

        <div className="form-group">
          <label>Token Address *</label>
          <small>0x0...0 for ETH, or ERC20 token contract address</small>
          <input 
            type="text" 
            placeholder="0x..."
            value={formData.token}
            onChange={(e) => setFormData({...formData, token: e.target.value})}
            disabled={isPending}
          />
        </div>

        <div className="form-group">
          <label>Max Amount (in smallest unit) *</label>
          <small>In wei for ETH (5000000000000000000 = 5 ETH), or smallest unit for tokens</small>
          <input 
            type="text" 
            placeholder="5000000000000000000"
            value={formData.maxAmount}
            onChange={(e) => setFormData({...formData, maxAmount: e.target.value})}
            disabled={isPending}
          />
        </div>

        <div className="form-group">
          <label>Duration (days) *</label>
          <small>How long until the session expires</small>
          <input 
            type="number" 
            placeholder="30"
            value={formData.duration}
            onChange={(e) => setFormData({...formData, duration: e.target.value})}
            disabled={isPending}
          />
        </div>

        <div className="form-group">
          <label>Max Transactions *</label>
          <small>Maximum number of transactions the session key can execute</small>
          <input 
            type="number" 
            placeholder="100"
            value={formData.maxNonce}
            onChange={(e) => setFormData({...formData, maxNonce: e.target.value})}
            disabled={isPending}
          />
        </div>

        <button type="submit" className="btn-primary" disabled={isPending}>
          {isPending ? '⏳ Creating...' : 'Create Session'}
        </button>
        <button type="button" className="btn-secondary" onClick={() => navigate('/')}>
          Cancel
        </button>
      </form>
    </div>
  )
}