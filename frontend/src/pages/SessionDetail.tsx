import { useParams, useNavigate } from 'react-router-dom'

export default function SessionDetail() {
  const { id } = useParams()
  const navigate = useNavigate()

  return (
    <div className="session-detail">
      <h2>Session #{id}</h2>
      <p>Loading session details...</p>
      <button className="btn-secondary" onClick={() => navigate('/')}>Back to Dashboard</button>
    </div>
  )
}
