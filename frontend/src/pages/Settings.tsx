import React, { useState } from 'react';
import '../styles/Settings.css';

const Settings: React.FC = () => {
  const [saved, setSaved] = useState(false);

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <div className="settings">
      <div className="settings-header">
        <h1>Settings</h1>
        <p>Customize your SessionFi experience</p>
      </div>

      {saved && (
        <div className="success-banner">
          <p>✅ Settings saved successfully</p>
        </div>
      )}

      <div className="settings-container">
        <div className="settings-section">
          <h2>Information</h2>
          <div className="info-item">
            <h3>About SessionFi</h3>
            <p>SessionFi is a security-focused smart contract authorization layer for Web3.</p>
            <p><strong>Version:</strong> 1.0.0<br/><strong>Network:</strong> Sepolia Testnet<br/><strong>Status:</strong> Beta</p>
          </div>

          <div className="info-item">
            <h3>Resources</h3>
            <ul>
              <li>
                <a href="https://github.com/sessionfi" target="_blank" rel="noopener noreferrer">
                  GitHub Repository
                </a>
              </li>
              <li>
                <a href="https://docs.sessionfi.dev" target="_blank" rel="noopener noreferrer">
                  Documentation
                </a>
              </li>
              <li>
                <a href="https://discord.gg/sessionfi" target="_blank" rel="noopener noreferrer">
                  Community Discord
                </a>
              </li>
              <li>
                <a href="mailto:security@sessionfi.dev">Report Security Issues</a>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <div className="settings-footer">
        <button className="btn-primary" onClick={handleSave}>
          💾 Save Settings
        </button>
      </div>
    </div>
  );
};

export default Settings;
