import React, { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { useSessionFi } from '../hooks/useSessionFi';
import '../styles/Dashboard.css';

const Dashboard: React.FC = () => {
  const { address } = useAccount();
  const { userSessions, stats, isLoading, error, refresh } = useSessionFi();
  const [activeFilter, setActiveFilter] = useState<'all' | 'active' | 'expired'>('active');

  useEffect(() => {
    refresh();
    const interval = setInterval(refresh, 30000);
    return () => clearInterval(interval);
  }, [refresh]);

  return (
    <div className="dashboard">
      <div className="dashboard-header">
        <h1>Session Dashboard</h1>
        <p>Manage your delegated execution sessions</p>
      </div>

      {error && (
        <div className="error-banner">
          <p>{error}</p>
        </div>
      )}

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-label">Total Sessions</div>
          <div className="stat-value">{stats.totalSessions}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Active Sessions</div>
          <div className="stat-value">{stats.activeSessions}</div>
        </div>
      </div>

      <div className="sessions-section">
        <div className="section-header">
          <h2>Your Sessions</h2>
          <div className="filter-buttons">
            <button
              className={`filter-btn ${activeFilter === 'active' ? 'active' : ''}`}
              onClick={() => setActiveFilter('active')}
            >
              Active
            </button>
            <button
              className={`filter-btn ${activeFilter === 'expired' ? 'active' : ''}`}
              onClick={() => setActiveFilter('expired')}
            >
              Expired
            </button>
            <button
              className={`filter-btn ${activeFilter === 'all' ? 'active' : ''}`}
              onClick={() => setActiveFilter('all')}
            >
              All
            </button>
          </div>
        </div>

        {isLoading ? (
          <div className="loading-state">
            <div className="spinner"></div>
            <p>Loading sessions...</p>
          </div>
        ) : userSessions.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📋</div>
            <h3>No sessions yet</h3>
            <p>Create your first session to get started with delegated execution</p>
            <a href="/create" className="cta-button">
              Create Session
            </a>
          </div>
        ) : (
          <div className="sessions-grid">
            {userSessions.map((session) => (
              <div key={session.id} className="session-card">
                <h3>Session {session.id.slice(0, 6)}</h3>
                <p>Status: {session.active ? '🟢 Active' : '🔴 Inactive'}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default Dashboard;
