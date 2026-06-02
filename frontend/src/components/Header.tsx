import { ConnectButton } from '@rainbow-me/rainbowkit'
import { Link } from 'react-router-dom'
import { useAccount } from 'wagmi'

export default function Header() {
  const { isConnected } = useAccount()

  return (
    <header className="header">
      <div className="header-container">
        <Link to="/" className="logo">
          <h1>SessionFi</h1>
        </Link>
        <nav className="nav">
          {isConnected && (
            <>
              <Link to="/">Dashboard</Link>
              <Link to="/create">Create Session</Link>
            </>
          )}
        </nav>
        <ConnectButton />
      </div>
    </header>
  )
}
