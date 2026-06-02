import { useState } from 'react'
import { useNavigate } from 'react-router-dom'

export default function CreateSession() {
  const navigate = useNavigate()
  const [formData, setFormData] = useState({
    sessionKey: '',
    targetContract: '',
    functionSelector: '',
    token: '',
    maxAmount: '',
    duration: '1',
    maxNonce: '10',
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    console.log('Creating session:', formData)
    // Session creation logic here
  }

  return (
    <div className="create-session">
      <h2>Create New Session</h2>
      
      <form onSubmit={handleSubmit} className="session-form">
        <div className="form-group">
          <label>Session Key Address</label>
          <input 
            type="text" 
            placeholder="0x..." 
            value={formData.sessionKey}
            onChange={(e) => setFormData({...formData, sessionKey: e.target.value})}
            required
          />
        </div>

        <div className="form-group">
          <label>Target Contract</label>
          <input 
            type="text" 
            placeholder="0x..." 
            value={formData.targetContract}
            onChange={(e) => setFormData({...formData, targetContract: e.target.value})}
            required
          />
        </div>

        <div className="form-group">
          <label>Function Selector</label>
          <input 
            type="text" 
            placeholder="0x12345678" 
            value={formData.functionSelector}
            onChange={(e) => setFormData({...formData, functionSelector: e.target.value})}
            required
          />
        </div>

        <div className="form-group">
          <label>Token (0x0 for ETH)</label>
          <input 
            type="text" 
            placeholder="0x..." 
            value={formData.token}
            onChange={(e) => setFormData({...formData, token: e.target.value})}
            required
          />
        </div>

        <div className="form-group">
          <label>Max Amount</label>
          <input 
            type="number" 
            placeholder="100" 
            value={formData.maxAmount}
            onChange={(e) => setFormData({...formData, maxAmount: e.target.value})}
            required
          />
        </div>

        <div className="form-group">
          <label>Duration (days)</label>
          <input 
            type="number" 
            placeholder="1" 
            value={formData.duration}
            onChange={(e) => setFormData({...formData, duration: e.target.value})}
            required
          />
        </div>

        <div className="form-group">
          <label>Max Transactions</label>
          <input 
            type="number" 
            placeholder="10" 
            value={formData.maxNonce}
            onChange={(e) => setFormData({...formData, maxNonce: e.target.value})}
            required
          />
        </div>

        <button type="submit" className="btn-primary">Create Session</button>
        <button type="button" className="btn-secondary" onClick={() => navigate('/')}>Cancel</button>
      </form>
    </div>
  )
}
