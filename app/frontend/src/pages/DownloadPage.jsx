import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { toast } from 'react-toastify';
import { FaDownload, FaLock, FaSpinner, FaFile, FaClock, FaExclamationTriangle } from 'react-icons/fa';

const DownloadPage = () => {
  const { token } = useParams();
  const [fileInfo, setFileInfo] = useState(null);
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(true);
  const [downloading, setDownloading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (token) {
      fetchFileInfo();
    }
  }, [token]);

  const fetchFileInfo = async () => {
    try {
      setLoading(true);
      const response = await fetch(`/api/download/${token}`);
      const result = await response.json();
      
      if (result.success) {
        setFileInfo(result.data);
      } else {
        setError(result.error?.message || 'Arquivo não encontrado');
      }
    } catch (error) {
      console.error('Erro ao buscar informações do arquivo:', error);
      setError('Erro ao conectar com o servidor');
    } finally {
      setLoading(false);
    }
  };

  const handleDownload = async (e) => {
    e.preventDefault();
    
    if (!password) {
      toast.error('Digite a senha para fazer o download');
      return;
    }
    
    setDownloading(true);
    
    try {
      const response = await fetch(`/api/download/${token}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ password })
      });
      
      if (response.ok) {
        // Criar blob do arquivo e fazer download
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.style.display = 'none';
        a.href = url;
        a.download = fileInfo.filename;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
        
        toast.success('Download realizado com sucesso!');
        
        // Atualizar informações do arquivo
        fetchFileInfo();
      } else {
        const result = await response.json();
        throw new Error(result.error?.message || 'Erro no download');
      }
    } catch (error) {
      console.error('Erro no download:', error);
      if (error.message.includes('Senha incorreta')) {
        toast.error('Senha incorreta. Tente novamente.');
      } else {
        toast.error(error.message || 'Erro ao fazer download');
      }
    } finally {
      setDownloading(false);
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatTimeRemaining = (expiresAt) => {
    const now = new Date();
    const expiry = new Date(expiresAt);
    const diff = expiry - now;
    
    if (diff <= 0) return 'Expirado';
    
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    
    if (hours > 0) {
      return `${hours}h ${minutes}m restantes`;
    }
    return `${minutes}m restantes`;
  };

  if (loading) {
    return (
      <div className="download-page">
        <div className="container">
          <div className="card loading-card">
            <div className="loading">
              <FaSpinner className="spinner" />
              Carregando informações do arquivo...
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="download-page">
        <div className="container">
          <div className="card error-card">
            <div className="error-content">
              <FaExclamationTriangle className="error-icon" />
              <h2>Arquivo Não Disponível</h2>
              <p>{error}</p>
              
              <div className="error-reasons">
                <h3>Possíveis motivos:</h3>
                <ul>
                  <li>Link expirado</li>
                  <li>Arquivo removido</li>
                  <li>Limite de downloads excedido</li>
                  <li>Link inválido ou corrompido</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="download-page">
      <div className="container">
        <h1>Download de Arquivo</h1>
        
        <div className="card download-card">
          {/* Informações do arquivo */}
          <div className="file-info-section">
            <div className="file-icon">
              <FaFile />
            </div>
            
            <div className="file-details">
              <h2>{fileInfo.filename}</h2>
              <div className="file-meta">
                <div className="meta-item">
                  <strong>Tamanho:</strong> {formatFileSize(fileInfo.size)}
                </div>
                <div className="meta-item">
                  <strong>Enviado em:</strong> {new Date(fileInfo.uploadedAt).toLocaleString()}
                </div>
                <div className="meta-item">
                  <FaClock className="meta-icon" />
                  <strong>Expira:</strong> {formatTimeRemaining(fileInfo.expiresAt)}
                </div>
                <div className="meta-item">
                  <strong>Downloads:</strong> {fileInfo.downloads}/{fileInfo.maxDownloads}
                </div>
              </div>
            </div>
          </div>
          
          {/* Formulário de download */}
          <div className="download-section">
            <form onSubmit={handleDownload}>
              <div className="form-group">
                <label htmlFor="password" className="form-label">
                  <FaLock className="label-icon" />
                  Senha de Proteção
                </label>
                <input
                  type="password"
                  id="password"
                  className="form-input"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Digite a senha fornecida"
                  required
                  autoFocus
                />
                <div className="form-help">
                  Digite a senha que foi definida no momento do upload.
                </div>
              </div>
              
              <button 
                type="submit" 
                className="btn btn-primary btn-large"
                disabled={!password || downloading || fileInfo.remainingDownloads <= 0}
              >
                {downloading ? (
                  <>
                    <FaSpinner className="spinner" />
                    Fazendo Download...
                  </>
                ) : (
                  <>
                    <FaDownload />
                    Fazer Download
                  </>
                )}
              </button>
              
              {fileInfo.remainingDownloads <= 0 && (
                <div className="alert alert-error">
                  Limite de downloads excedido. Este arquivo não está mais disponível.
                </div>
              )}
            </form>
          </div>
          
          {/* Avisos de segurança */}
          <div className="security-info">
            <h3>🔒 Informações de Segurança:</h3>
            <ul>
              <li>Este arquivo está protegido por criptografia AES-256</li>
              <li>Somente quem possui a senha correta pode fazer o download</li>
              <li>O arquivo será removido automaticamente após a expiração</li>
              <li>Downloads são limitados para maior segurança</li>
            </ul>
          </div>
        </div>
      </div>
      
      <style jsx>{`
        .download-page {
          max-width: 700px;
          margin: 0 auto;
        }
        
        .loading-card,
        .error-card {
          text-align: center;
          padding: 3rem 2rem;
        }
        
        .error-content {
          max-width: 500px;
          margin: 0 auto;
        }
        
        .error-icon {
          font-size: 3rem;
          color: #e53e3e;
          margin-bottom: 1rem;
        }
        
        .error-reasons {
          background: #fed7d7;
          border: 1px solid #fc8181;
          border-radius: 8px;
          padding: 1.5rem;
          margin-top: 1.5rem;
          text-align: left;
        }
        
        .error-reasons h3 {
          color: #742a2a;
          margin-bottom: 1rem;
          font-size: 1rem;
        }
        
        .error-reasons ul {
          color: #742a2a;
          margin: 0;
          padding-left: 1.5rem;
        }
        
        .file-info-section {
          display: flex;
          gap: 1.5rem;
          align-items: flex-start;
          margin-bottom: 2rem;
          padding-bottom: 2rem;
          border-bottom: 1px solid #e2e8f0;
        }
        
        .file-icon {
          font-size: 3rem;
          color: #667eea;
          flex-shrink: 0;
        }
        
        .file-details h2 {
          color: #2d3748;
          margin-bottom: 1rem;
          word-break: break-word;
        }
        
        .file-meta {
          display: grid;
          gap: 0.5rem;
        }
        
        .meta-item {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          color: #4a5568;
          font-size: 0.9rem;
        }
        
        .meta-icon {
          color: #667eea;
        }
        
        .download-section {
          margin-bottom: 2rem;
        }
        
        .label-icon {
          margin-right: 0.5rem;
          color: #667eea;
        }
        
        .btn-large {
          width: 100%;
          padding: 1rem 2rem;
          font-size: 1.1rem;
        }
        
        .security-info {
          background: #ebf8ff;
          border: 1px solid #63b3ed;
          border-radius: 8px;
          padding: 1.5rem;
        }
        
        .security-info h3 {
          color: #2c5282;
          margin-bottom: 1rem;
          font-size: 1rem;
        }
        
        .security-info ul {
          color: #2c5282;
          margin: 0;
          padding-left: 1.5rem;
        }
        
        .security-info li {
          margin-bottom: 0.5rem;
        }
        
        @media (max-width: 768px) {
          .file-info-section {
            flex-direction: column;
            text-align: center;
            gap: 1rem;
          }
          
          .file-icon {
            align-self: center;
          }
        }
      `}</style>
    </div>
  );
};

export default DownloadPage;
