import { useAccount } from 'wagmi'
import { Link } from 'react-router-dom'

export default function Dashboard() {
  const { address } = useAccount()

  return (
    <div className="dashboard">
      <h2>Dashboard</h2>
      <p>Wallet: {address?.slice(0, 6)}...{address?.slice(-4)}</p>
      
      <div className="dashboard-content">
        <section className="sessions-section">
          <h3>Your Sessions</h3>
          <div className="sessions-list">
            <p>Loading sessions...</p>
          </div>
        </section>

        <section className="actions-section">
          <Link to="/create" className="btn-primary">+ Create New Session</Link>
        </section>
      </div>
    </div>
  )
}
