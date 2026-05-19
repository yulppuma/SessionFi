import React from 'react';
import { useNavigate } from 'react-router-dom';
import '../styles/Pages.css';

export const SessionDetail: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="session-detail">
      <div className="detail-header">
        <button className="btn-back" onClick={() => navigate('/')}>
          ← Back
        </button>
        <h1>Session Details</h1>
      </div>

      <div className="detail-container">
        <p>Session details will load here once contract integration is complete.</p>
      </div>
    </div>
  );
};

export const Settings: React.FC = () => {
  const [saved, setSaved] = React.useState(false);

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
          <h2>Preferences</h2>
          <p>Settings panel coming soon...</p>
        </div>

        <div className="settings-section">
          <h2>Information</h2>
          <div className="info-item">
            <h3>About SessionFi</h3>
            <p>SessionFi is a security-focused smart contract authorization layer.</p>
            <p><strong>Version:</strong> 1.0.0<br/><strong>Network:</strong> Sepolia Testnet</p>
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

export default SessionDetail;
