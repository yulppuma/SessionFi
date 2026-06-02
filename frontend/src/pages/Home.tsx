import { ConnectButton } from '@rainbow-me/rainbowkit'

export default function Home() {
  return (
    <div className="home">
      <div className="home-hero">
        <h2>Welcome to SessionFi</h2>
        <p>Secure delegation for smart contract authorization</p>
        <p>Create limited, scoped sessions to delegate blockchain operations safely.</p>
        
        <div className="features">
          <div className="feature">
            <h3>🔐 Secure</h3>
            <p>Scoped permissions with spending limits and time expiration</p>
          </div>
          <div className="feature">
            <h3>🤖 Automation</h3>
            <p>Enable AI agents and automated protocols</p>
          </div>
          <div className="feature">
            <h3>💰 Control</h3>
            <p>Fine-grained control over delegated operations</p>
          </div>
        </div>

        <div className="cta">
          <h3>Get Started</h3>
          <p>Connect your wallet to create your first session</p>
          <ConnectButton />
        </div>
      </div>
    </div>
  )
}
