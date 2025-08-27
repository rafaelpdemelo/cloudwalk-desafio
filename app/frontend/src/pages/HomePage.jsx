import React from 'react';
import { Link } from 'react-router-dom';
import { FaShieldAlt, FaUpload, FaDownload, FaLock, FaClock, FaCheck } from 'react-icons/fa';

const HomePage = () => {
  return (
    <div className="home-page">
      <div className="hero-section">
        <div className="container">
          <div className="card hero-card">
            <div className="hero-content">
              <h1>
                <FaShieldAlt className="hero-icon" />
                Compartilhamento Seguro de Arquivos
              </h1>
              <p className="hero-description">
                Envie e compartilhe arquivos com criptografia end-to-end. 
                Seus dados ficam protegidos com senhas personalizadas e links temporários.
              </p>
              
              <div className="cta-buttons">
                <Link to="/upload" className="btn btn-primary btn-large">
                  <FaUpload />
                  Enviar Arquivo
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="features-section">
        <div className="container">
          <h2 className="section-title">Recursos de Segurança</h2>
          
          <div className="features-grid">
            <div className="feature-card">
              <div className="feature-icon">
                <FaLock />
              </div>
              <h3>Criptografia AES-256</h3>
              <p>
                Todos os arquivos são criptografados com algoritmo AES-256-GCM
                antes de serem armazenados, garantindo máxima proteção.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">
                <FaClock />
              </div>
              <h3>Links Temporários</h3>
              <p>
                Configure o tempo de expiração dos links de download.
                Arquivos são automaticamente removidos após o período definido.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">
                <FaCheck />
              </div>
              <h3>Auditoria Completa</h3>
              <p>
                Logs detalhados de todas as operações para rastreabilidade
                e conformidade com políticas de segurança.
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="how-it-works">
        <div className="container">
          <h2 className="section-title">Como Funciona</h2>
          
          <div className="steps">
            <div className="step">
              <div className="step-number">1</div>
              <div className="step-content">
                <h3>Envie o Arquivo</h3>
                <p>Faça upload do arquivo e defina uma senha para proteção</p>
              </div>
            </div>

            <div className="step">
              <div className="step-number">2</div>
              <div className="step-content">
                <h3>Receba o Link</h3>
                <p>Um link único e temporário será gerado para compartilhamento</p>
              </div>
            </div>

            <div className="step">
              <div className="step-number">3</div>
              <div className="step-content">
                <h3>Compartilhe com Segurança</h3>
                <p>Envie o link e a senha separadamente para máxima segurança</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <style jsx>{`
        .home-page {
          min-height: 100vh;
        }

        .hero-section {
          margin-bottom: 4rem;
        }

        .hero-card {
          text-align: center;
          max-width: 800px;
          margin: 0 auto;
        }

        .hero-content {
          padding: 2rem 0;
        }

        .hero-icon {
          font-size: 3rem;
          color: #667eea;
          margin-bottom: 1rem;
          display: block;
          margin: 0 auto 1rem;
        }

        .hero-description {
          font-size: 1.2rem;
          color: #4a5568;
          margin-bottom: 2rem;
          line-height: 1.7;
        }

        .cta-buttons {
          display: flex;
          gap: 1rem;
          justify-content: center;
          flex-wrap: wrap;
        }

        .btn-large {
          padding: 1rem 2rem;
          font-size: 1.1rem;
          min-width: 200px;
        }

        .section-title {
          text-align: center;
          margin-bottom: 3rem;
          color: white;
        }

        .features-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
          gap: 2rem;
          margin-bottom: 4rem;
        }

        .feature-card {
          background: rgba(255, 255, 255, 0.95);
          padding: 2rem;
          border-radius: 16px;
          text-align: center;
          box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
          backdrop-filter: blur(10px);
          border: 1px solid rgba(255, 255, 255, 0.2);
          transition: transform 0.2s ease;
        }

        .feature-card:hover {
          transform: translateY(-5px);
        }

        .feature-icon {
          width: 60px;
          height: 60px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0 auto 1rem;
          color: white;
          font-size: 1.5rem;
        }

        .steps {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: 2rem;
          max-width: 900px;
          margin: 0 auto;
        }

        .step {
          display: flex;
          align-items: flex-start;
          gap: 1rem;
          background: rgba(255, 255, 255, 0.95);
          padding: 1.5rem;
          border-radius: 12px;
          backdrop-filter: blur(10px);
        }

        .step-number {
          width: 40px;
          height: 40px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: bold;
          font-size: 1.1rem;
          flex-shrink: 0;
        }

        .step-content h3 {
          margin-bottom: 0.5rem;
          color: #2d3748;
        }

        .step-content p {
          color: #4a5568;
          margin: 0;
        }

        @media (max-width: 768px) {
          .hero-card {
            margin: 0 1rem;
          }

          .hero-icon {
            font-size: 2.5rem;
          }

          .hero-description {
            font-size: 1.1rem;
          }

          .cta-buttons {
            flex-direction: column;
            align-items: center;
          }

          .btn-large {
            min-width: auto;
            width: 100%;
            max-width: 300px;
          }

          .features-grid {
            grid-template-columns: 1fr;
            gap: 1.5rem;
          }

          .steps {
            grid-template-columns: 1fr;
          }

          .step {
            flex-direction: column;
            text-align: center;
          }
        }
      `}</style>
    </div>
  );
};

export default HomePage;
