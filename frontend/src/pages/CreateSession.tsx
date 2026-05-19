import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useSessionFi } from '../hooks/useSessionFi';
import '../styles/CreateSession.css';

const CreateSession: React.FC = () => {
  const navigate = useNavigate();
  const { createSession, isLoading, error } = useSessionFi();

  const [formData, setFormData] = useState({
    sessionKey: '',
    targetContract: '',
    functionSelector: '0x',
    maxSpend: '100',
    token: '',
    duration: 1,
    maxNonce: 10,
  });

  const [formError, setFormError] = useState<string | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Basic validation
    if (!formData.sessionKey || !formData.targetContract || !formData.token) {
      setFormError('Please fill in all required fields');
      return;
    }

    try {
      await createSession(formData);
      setTimeout(() => {
        navigate('/');
      }, 1500);
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Failed to create session');
    }
  };

  return (
    <div className="create-session">
      <div className="create-header">
        <h1>Create New Session</h1>
        <p>Set up delegated execution with granular permissions</p>
      </div>

      {(error || formError) && (
        <div className="error-banner">
          <p>⚠️ {error || formError}</p>
        </div>
      )}

      <form className="session-form" onSubmit={handleSubmit}>
        <div className="form-section">
          <h2>Authorization Details</h2>

          <div className="form-group">
            <label htmlFor="sessionKey">Session Key Address *</label>
            <input
              type="text"
              id="sessionKey"
              name="sessionKey"
              placeholder="0x..."
              value={formData.sessionKey}
              onChange={handleChange}
            />
          </div>

          <div className="form-group">
            <label htmlFor="targetContract">Target Contract Address *</label>
            <input
              type="text"
              id="targetContract"
              name="targetContract"
              placeholder="0x..."
              value={formData.targetContract}
              onChange={handleChange}
            />
          </div>

          <div className="form-group">
            <label htmlFor="functionSelector">Function Selector *</label>
            <input
              type="text"
              id="functionSelector"
              name="functionSelector"
              placeholder="0x12345678"
              value={formData.functionSelector}
              onChange={handleChange}
            />
          </div>
        </div>

        <div className="form-section">
          <h2>Spending Limits</h2>

          <div className="form-group">
            <label htmlFor="token">Token Address *</label>
            <input
              type="text"
              id="token"
              name="token"
              placeholder="0x..."
              value={formData.token}
              onChange={handleChange}
            />
          </div>

          <div className="form-group">
            <label htmlFor="maxSpend">Maximum Spend Amount *</label>
            <input
              type="number"
              id="maxSpend"
              name="maxSpend"
              step="0.01"
              value={formData.maxSpend}
              onChange={handleChange}
            />
          </div>
        </div>

        <div className="form-section">
          <h2>Session Duration</h2>

          <div className="form-group">
            <label htmlFor="duration">Duration (days) *</label>
            <input
              type="number"
              id="duration"
              name="duration"
              min="1"
              value={formData.duration}
              onChange={handleChange}
            />
          </div>

          <div className="form-group">
            <label htmlFor="maxNonce">Maximum Transactions *</label>
            <input
              type="number"
              id="maxNonce"
              name="maxNonce"
              min="1"
              value={formData.maxNonce}
              onChange={handleChange}
            />
          </div>
        </div>

        <button type="submit" className="btn-submit" disabled={isLoading}>
          {isLoading ? 'Creating...' : 'Create Session'}
        </button>
      </form>
    </div>
  );
};

export default CreateSession;
