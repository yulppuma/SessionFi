import React from 'react';
import '../styles/Footer.css';

const Footer: React.FC = () => {
  return (
    <footer className="footer">
      <div className="footer-container">
        <div className="footer-section">
          <h3>SessionFi</h3>
          <p>Scoped delegated execution for automated Web3 interactions</p>
        </div>

        <div className="footer-section">
          <h4>Resources</h4>
          <ul>
            <li>
              <a href="https://github.com/sessionfi" target="_blank" rel="noopener noreferrer">
                GitHub
              </a>
            </li>
            <li>
              <a href="https://docs.sessionfi.dev" target="_blank" rel="noopener noreferrer">
                Documentation
              </a>
            </li>
            <li>
              <a href="https://discord.gg/sessionfi" target="_blank" rel="noopener noreferrer">
                Discord
              </a>
            </li>
          </ul>
        </div>

        <div className="footer-section">
          <h4>Security</h4>
          <ul>
            <li>
              <a href="mailto:security@sessionfi.dev">Report a Bug</a>
            </li>
            <li>
              <a href="https://docs.sessionfi.dev/security" target="_blank" rel="noopener noreferrer">
                Security Policy
              </a>
            </li>
          </ul>
        </div>

        <div className="footer-section">
          <h4>Legal</h4>
          <ul>
            <li>
              <a href="https://sessionfi.dev/terms" target="_blank" rel="noopener noreferrer">
                Terms of Service
              </a>
            </li>
            <li>
              <a href="https://sessionfi.dev/privacy" target="_blank" rel="noopener noreferrer">
                Privacy Policy
              </a>
            </li>
          </ul>
        </div>
      </div>

      <div className="footer-bottom">
        <p>&copy; 2024 SessionFi. Built with ❤️ by the community.</p>
        <p className="disclaimer">
          SessionFi is experimental software. Use at your own risk. Always review transaction signatures.
        </p>
      </div>
    </footer>
  );
};

export default Footer;
