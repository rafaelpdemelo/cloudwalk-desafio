import React from 'react';
import { FaShieldAlt, FaGithub, FaHeart } from 'react-icons/fa';

const Footer = () => {
  return (
    <footer className="footer">
      <div className="footer-container">
        <div className="footer-content">
          <div className="footer-section">
            <div className="footer-brand">
              <FaShieldAlt className="footer-icon" />
              <span>Secure File Share</span>
            </div>
            <p className="footer-description">
              Compartilhamento seguro de arquivos com criptografia end-to-end
            </p>
          </div>
          
          <div className="footer-section">
            <h4>Recursos de Segurança</h4>
            <ul className="footer-links">
              <li>Criptografia AES-256</li>
              <li>Links temporários</li>
              <li>Auditoria completa</li>
              <li>Rate limiting</li>
            </ul>
          </div>
          
          <div className="footer-section">
            <h4>CloudWalk Challenge</h4>
            <p className="footer-text">
              Desenvolvido para demonstrar melhores práticas de segurança em Kubernetes
            </p>
            <div className="footer-tech">
              <span className="tech-badge">Kubernetes</span>
              <span className="tech-badge">ArgoCD</span>
              <span className="tech-badge">React</span>
              <span className="tech-badge">Node.js</span>
            </div>
          </div>
        </div>
        
        <div className="footer-bottom">
          <p className="footer-copyright">
            Feito com <FaHeart className="heart-icon" /> para o desafio CloudWalk
          </p>
          <p className="footer-note">
            ⚠️ Esta é uma aplicação de demonstração com certificados self-signed
          </p>
        </div>
      </div>
      
      <style jsx>{`
        .footer {
          background: rgba(0, 0, 0, 0.1);
          backdrop-filter: blur(10px);
          border-top: 1px solid rgba(255, 255, 255, 0.1);
          margin-top: auto;
          color: white;
        }
        
        .footer-container {
          max-width: 1200px;
          margin: 0 auto;
          padding: 2rem 1rem 1rem;
        }
        
        .footer-content {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: 2rem;
          margin-bottom: 2rem;
        }
        
        .footer-section h4 {
          color: white;
          margin-bottom: 1rem;
          font-size: 1.1rem;
          font-weight: 600;
        }
        
        .footer-brand {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          font-size: 1.2rem;
          font-weight: 600;
          margin-bottom: 1rem;
        }
        
        .footer-icon {
          font-size: 1.5rem;
          color: #667eea;
        }
        
        .footer-description,
        .footer-text {
          color: rgba(255, 255, 255, 0.8);
          line-height: 1.6;
          margin-bottom: 1rem;
        }
        
        .footer-links {
          list-style: none;
          padding: 0;
        }
        
        .footer-links li {
          color: rgba(255, 255, 255, 0.7);
          margin-bottom: 0.5rem;
          font-size: 0.9rem;
        }
        
        .footer-links li:before {
          content: "✓ ";
          color: #667eea;
          font-weight: bold;
        }
        
        .footer-tech {
          display: flex;
          flex-wrap: wrap;
          gap: 0.5rem;
          margin-top: 1rem;
        }
        
        .tech-badge {
          background: rgba(102, 126, 234, 0.2);
          color: #667eea;
          padding: 0.25rem 0.75rem;
          border-radius: 20px;
          font-size: 0.8rem;
          font-weight: 500;
          border: 1px solid rgba(102, 126, 234, 0.3);
        }
        
        .footer-bottom {
          border-top: 1px solid rgba(255, 255, 255, 0.1);
          padding-top: 1rem;
          text-align: center;
        }
        
        .footer-copyright {
          color: rgba(255, 255, 255, 0.8);
          margin-bottom: 0.5rem;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 0.5rem;
        }
        
        .heart-icon {
          color: #e53e3e;
          animation: heartbeat 1.5s ease-in-out infinite;
        }
        
        @keyframes heartbeat {
          0% { transform: scale(1); }
          50% { transform: scale(1.1); }
          100% { transform: scale(1); }
        }
        
        .footer-note {
          color: rgba(255, 255, 255, 0.6);
          font-size: 0.8rem;
        }
        
        @media (max-width: 768px) {
          .footer-container {
            padding: 1.5rem 0.5rem 1rem;
          }
          
          .footer-content {
            grid-template-columns: 1fr;
            gap: 1.5rem;
          }
          
          .footer-tech {
            justify-content: center;
          }
          
          .footer-copyright {
            flex-direction: column;
            gap: 0.25rem;
          }
        }
      `}</style>
    </footer>
  );
};

export default Footer;
