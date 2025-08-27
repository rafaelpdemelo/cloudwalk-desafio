import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { FaShieldAlt, FaUpload, FaDownload, FaHome } from 'react-icons/fa';

const Header = () => {
  const location = useLocation();

  return (
    <header className="header">
      <div className="header-container">
        <Link to="/" className="logo">
          <FaShieldAlt className="logo-icon" />
          <span className="logo-text">Secure File Share</span>
        </Link>
        
        <nav className="nav">
          <Link 
            to="/" 
            className={`nav-link ${location.pathname === '/' ? 'active' : ''}`}
          >
            <FaHome />
            <span>Início</span>
          </Link>
          <Link 
            to="/upload" 
            className={`nav-link ${location.pathname === '/upload' ? 'active' : ''}`}
          >
            <FaUpload />
            <span>Enviar</span>
          </Link>
        </nav>
      </div>
      
      <style jsx>{`
        .header {
          background: rgba(255, 255, 255, 0.1);
          backdrop-filter: blur(10px);
          border-bottom: 1px solid rgba(255, 255, 255, 0.2);
          padding: 1rem 0;
        }
        
        .header-container {
          max-width: 1200px;
          margin: 0 auto;
          padding: 0 1rem;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        
        .logo {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          color: white;
          text-decoration: none;
          font-weight: 600;
          font-size: 1.25rem;
        }
        
        .logo:hover {
          color: rgba(255, 255, 255, 0.9);
          text-decoration: none;
        }
        
        .logo-icon {
          font-size: 1.5rem;
        }
        
        .nav {
          display: flex;
          gap: 1rem;
        }
        
        .nav-link {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          color: rgba(255, 255, 255, 0.8);
          text-decoration: none;
          padding: 0.5rem 1rem;
          border-radius: 8px;
          transition: all 0.2s ease;
          font-weight: 500;
        }
        
        .nav-link:hover {
          color: white;
          background: rgba(255, 255, 255, 0.1);
          text-decoration: none;
        }
        
        .nav-link.active {
          color: white;
          background: rgba(255, 255, 255, 0.2);
        }
        
        @media (max-width: 768px) {
          .header-container {
            padding: 0 0.5rem;
          }
          
          .logo-text {
            display: none;
          }
          
          .nav-link span {
            display: none;
          }
          
          .nav-link {
            padding: 0.5rem;
          }
        }
      `}</style>
    </header>
  );
};

export default Header;
