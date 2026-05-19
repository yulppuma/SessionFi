import React, { useEffect } from 'react';
import { useAccount } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { Link } from 'react-router-dom';
import '../styles/Header.css';

interface HeaderProps {
  onConnectionChange: (isConnected: boolean) => void;
}

const Header: React.FC<HeaderProps> = ({ onConnectionChange }) => {
  const { isConnected, address } = useAccount();

  useEffect(() => {
    onConnectionChange(isConnected);
  }, [isConnected, onConnectionChange]);

  const shortAddress = address ? `${address.slice(0, 6)}...${address.slice(-4)}` : '';

  return (
    <header className="header">
      <div className="header-container">
        <Link to="/" className="logo">
          <span className="logo-icon">🔐</span>
          <span className="logo-text">SessionFi</span>
        </Link>

        {isConnected && (
          <nav className="nav">
            <Link to="/" className="nav-link">Dashboard</Link>
            <Link to="/create" className="nav-link">Create Session</Link>
            <Link to="/settings" className="nav-link">Settings</Link>
          </nav>
        )}

        <div className="header-right">
          {isConnected && (
            <div className="connected-info">
              <span className="address-badge">{shortAddress}</span>
            </div>
          )}
          <ConnectButton />
        </div>
      </div>
    </header>
  );
};

export default Header;
