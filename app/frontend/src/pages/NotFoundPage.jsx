import React from 'react';
import { Link } from 'react-router-dom';
import { FaExclamationTriangle, FaHome, FaUpload } from 'react-icons/fa';

const NotFoundPage = () => {
  return (
    <div className="not-found-page">
      <div className="container">
        <div className="card not-found-card">
          <div className="not-found-icon">
            <FaExclamationTriangle />
          </div>
          
          <h1>404 - Página Não Encontrada</h1>
          
          <p className="not-found-message">
            A página que você está procurando não existe ou pode ter sido removida.
          </p>
          
          <div className="not-found-actions">
            <Link to="/" className="btn btn-primary">
              <FaHome />
              Voltar ao Início
            </Link>
            
            <Link to="/upload" className="btn btn-secondary">
              <FaUpload />
              Enviar Arquivo
            </Link>
          </div>
          
          <div className="not-found-help">
            <h3>O que você pode fazer:</h3>
            <ul>
              <li>Verificar se o URL está correto</li>
              <li>Voltar à página inicial</li>
              <li>Fazer upload de um novo arquivo</li>
              <li>Verificar se o link de download não expirou</li>
            </ul>
          </div>
        </div>
      </div>
      
      <style jsx>{`
        .not-found-page {
          min-height: 70vh;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        
        .not-found-card {
          text-align: center;
          max-width: 600px;
          margin: 0 auto;
        }
        
        .not-found-icon {
          font-size: 4rem;
          color: #f6ad55;
          margin-bottom: 1rem;
        }
        
        .not-found-message {
          font-size: 1.1rem;
          color: #4a5568;
          margin-bottom: 2rem;
        }
        
        .not-found-actions {
          display: flex;
          gap: 1rem;
          justify-content: center;
          margin-bottom: 2rem;
          flex-wrap: wrap;
        }
        
        .not-found-help {
          background: #f7fafc;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 1.5rem;
          text-align: left;
        }
        
        .not-found-help h3 {
          color: #2d3748;
          margin-bottom: 1rem;
          font-size: 1.1rem;
        }
        
        .not-found-help ul {
          list-style-type: none;
          padding: 0;
        }
        
        .not-found-help li {
          color: #4a5568;
          margin-bottom: 0.5rem;
          padding-left: 1rem;
          position: relative;
        }
        
        .not-found-help li:before {
          content: "•";
          color: #667eea;
          font-weight: bold;
          position: absolute;
          left: 0;
        }
        
        @media (max-width: 768px) {
          .not-found-icon {
            font-size: 3rem;
          }
          
          .not-found-actions {
            flex-direction: column;
            align-items: center;
          }
          
          .not-found-actions .btn {
            width: 100%;
            max-width: 250px;
          }
        }
      `}</style>
    </div>
  );
};

export default NotFoundPage;
