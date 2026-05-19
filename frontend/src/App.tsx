import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { WagmiProvider } from 'wagmi';
import { RainbowKitProvider } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';

import { wagmiConfig } from './config/wagmi';
import Header from './components/Header';
import Footer from './components/Footer';
import Dashboard from './pages/Dashboard';
import CreateSession from './pages/CreateSession';
import SessionDetail from './pages/SessionDetail';
import Settings from './pages/Settings';

import './styles/App.css';

const AppContent: React.FC = () => {
  const [isConnected, setIsConnected] = useState(false);

  return (
    <div className="app-container">
      <Header onConnectionChange={setIsConnected} />
      
      <main className="app-main">
        {isConnected ? (
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/create" element={<CreateSession />} />
            <Route path="/session/:id" element={<SessionDetail />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="*" element={<Dashboard />} />
          </Routes>
        ) : (
          <div className="connect-wallet-prompt">
            <div className="prompt-content">
              <h1>SessionFi</h1>
              <p>Scoped delegated execution for automated Web3 interactions</p>
              <p className="description">
                Connect your wallet to get started with secure session-based authorization
              </p>
              <div className="prompt-icon">🔐</div>
            </div>
          </div>
        )}
      </main>

      <Footer />
    </div>
  );
};

export default function App() {
  return (
    <WagmiProvider config={wagmiConfig}>
      <RainbowKitProvider>
        <Router>
          <AppContent />
        </Router>
      </RainbowKitProvider>
    </WagmiProvider>
  );
}
