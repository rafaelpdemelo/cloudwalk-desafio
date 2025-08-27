import React, { useState, useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { toast } from 'react-toastify';
import { FaCloudUploadAlt, FaCopy, FaCheck, FaSpinner } from 'react-icons/fa';

const UploadPage = () => {
  const [file, setFile] = useState(null);
  const [password, setPassword] = useState('');
  const [ttl, setTtl] = useState('24');
  const [uploading, setUploading] = useState(false);
  const [uploadResult, setUploadResult] = useState(null);
  const [linkCopied, setLinkCopied] = useState(false);

  const onDrop = useCallback((acceptedFiles, rejectedFiles) => {
    if (rejectedFiles.length > 0) {
      toast.error('Tipo de arquivo não suportado ou arquivo muito grande');
      return;
    }
    
    if (acceptedFiles.length > 0) {
      setFile(acceptedFiles[0]);
      toast.success('Arquivo selecionado com sucesso');
    }
  }, []);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/*': ['.jpeg', '.jpg', '.png', '.gif', '.webp'],
      'application/pdf': ['.pdf'],
      'text/plain': ['.txt'],
      'application/zip': ['.zip'],
      'application/json': ['.json'],
      'application/msword': ['.doc'],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx']
    },
    maxSize: 50 * 1024 * 1024, // 50MB
    multiple: false
  });

  const handleUpload = async (e) => {
    e.preventDefault();
    
    if (!file) {
      toast.error('Selecione um arquivo primeiro');
      return;
    }
    
    if (!password || password.length < 4) {
      toast.error('Senha deve ter pelo menos 4 caracteres');
      return;
    }
    
    setUploading(true);
    
    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('password', password);
      formData.append('ttl', ttl);
      
      const response = await fetch('/api/upload', {
        method: 'POST',
        body: formData
      });
      
      const result = await response.json();
      
      if (result.success) {
        setUploadResult(result.data);
        toast.success('Arquivo enviado com sucesso!');
        
        // Limpar formulário
        setFile(null);
        setPassword('');
      } else {
        throw new Error(result.error?.message || 'Erro no upload');
      }
    } catch (error) {
      console.error('Erro no upload:', error);
      toast.error(error.message || 'Erro ao enviar arquivo');
    } finally {
      setUploading(false);
    }
  };

  const copyToClipboard = async () => {
    try {
      await navigator.clipboard.writeText(uploadResult.downloadUrl);
      setLinkCopied(true);
      toast.success('Link copiado para a área de transferência!');
      
      setTimeout(() => setLinkCopied(false), 3000);
    } catch (error) {
      toast.error('Erro ao copiar link');
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  return (
    <div className="upload-page">
      <div className="container">
        <h1>Enviar Arquivo</h1>
        
        {!uploadResult ? (
          <div className="card upload-card">
            <form onSubmit={handleUpload}>
              {/* Dropzone */}
              <div className="form-group">
                <label className="form-label">Arquivo</label>
                <div 
                  {...getRootProps()} 
                  className={`dropzone ${isDragActive ? 'active' : ''} ${file ? 'has-file' : ''}`}
                >
                  <input {...getInputProps()} />
                  <div className="dropzone-content">
                    {file ? (
                      <>
                        <FaCheck className="dropzone-icon success" />
                        <p><strong>{file.name}</strong></p>
                        <p className="file-size">{formatFileSize(file.size)}</p>
                        <p className="dropzone-hint">Clique ou arraste para alterar</p>
                      </>
                    ) : (
                      <>
                        <FaCloudUploadAlt className="dropzone-icon" />
                        <p>
                          {isDragActive 
                            ? 'Solte o arquivo aqui...' 
                            : 'Arraste um arquivo aqui ou clique para selecionar'
                          }
                        </p>
                        <p className="dropzone-hint">
                          Máximo 50MB • PDF, Imagens, ZIP, DOC, TXT, JSON
                        </p>
                      </>
                    )}
                  </div>
                </div>
              </div>

              {/* Senha */}
              <div className="form-group">
                <label htmlFor="password" className="form-label">
                  Senha de Proteção
                </label>
                <input
                  type="password"
                  id="password"
                  className="form-input"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Digite uma senha segura"
                  minLength={4}
                  maxLength={128}
                  required
                />
                <div className="form-help">
                  Mínimo 4 caracteres. Esta senha será necessária para fazer download.
                </div>
              </div>

              {/* TTL */}
              <div className="form-group">
                <label htmlFor="ttl" className="form-label">
                  Tempo de Expiração
                </label>
                <select
                  id="ttl"
                  className="form-input"
                  value={ttl}
                  onChange={(e) => setTtl(e.target.value)}
                >
                  <option value="1">1 hora</option>
                  <option value="6">6 horas</option>
                  <option value="24">24 horas</option>
                  <option value="72">3 dias</option>
                  <option value="168">1 semana</option>
                </select>
                <div className="form-help">
                  Após este período, o arquivo será removido automaticamente.
                </div>
              </div>

              {/* Botão de envio */}
              <button 
                type="submit" 
                className="btn btn-primary btn-large"
                disabled={!file || !password || uploading}
              >
                {uploading ? (
                  <>
                    <FaSpinner className="spinner" />
                    Enviando...
                  </>
                ) : (
                  <>
                    <FaCloudUploadAlt />
                    Enviar Arquivo
                  </>
                )}
              </button>
            </form>
          </div>
        ) : (
          /* Resultado do upload */
          <div className="card success-card">
            <div className="success-header">
              <FaCheck className="success-icon" />
              <h2>Arquivo Enviado com Sucesso!</h2>
            </div>
            
            <div className="upload-info">
              <div className="info-item">
                <strong>Arquivo:</strong> {uploadResult.filename}
              </div>
              <div className="info-item">
                <strong>Tamanho:</strong> {formatFileSize(uploadResult.size)}
              </div>
              <div className="info-item">
                <strong>Expira em:</strong> {new Date(uploadResult.expiresAt).toLocaleString()}
              </div>
              <div className="info-item">
                <strong>Downloads máximos:</strong> {uploadResult.maxDownloads}
              </div>
            </div>
            
            <div className="download-link-section">
              <label className="form-label">Link para Download:</label>
              <div className="link-container">
                <input
                  type="text"
                  value={uploadResult.downloadUrl}
                  readOnly
                  className="form-input link-input selectable"
                />
                <button
                  type="button"
                  onClick={copyToClipboard}
                  className="btn btn-secondary copy-btn"
                >
                  {linkCopied ? <FaCheck /> : <FaCopy />}
                  {linkCopied ? 'Copiado!' : 'Copiar'}
                </button>
              </div>
            </div>
            
            <div className="security-notice">
              <h3>⚠️ Importante para Segurança:</h3>
              <ul>
                <li>Compartilhe o link e a senha <strong>separadamente</strong></li>
                <li>Use canais de comunicação diferentes (ex: link por email, senha por WhatsApp)</li>
                <li>Não envie link e senha na mesma mensagem</li>
                <li>O arquivo será removido automaticamente após a expiração</li>
              </ul>
            </div>
            
            <div className="actions">
              <button
                type="button"
                onClick={() => {
                  setUploadResult(null);
                  setLinkCopied(false);
                }}
                className="btn btn-primary"
              >
                Enviar Outro Arquivo
              </button>
            </div>
          </div>
        )}
      </div>
      
      <style jsx>{`
        .upload-page {
          max-width: 800px;
          margin: 0 auto;
        }
        
        .upload-card {
          max-width: 600px;
          margin: 0 auto;
        }
        
        .dropzone.has-file {
          border-color: #48bb78;
          background: rgba(72, 187, 120, 0.05);
        }
        
        .dropzone-icon.success {
          color: #48bb78;
        }
        
        .file-size {
          color: #718096;
          font-size: 0.9rem;
          margin: 0;
        }
        
        .dropzone-hint {
          font-size: 0.8rem;
          color: #a0aec0;
          margin-top: 0.5rem;
        }
        
        .btn-large {
          width: 100%;
          padding: 1rem 2rem;
          font-size: 1.1rem;
        }
        
        .success-card {
          max-width: 700px;
          margin: 0 auto;
        }
        
        .success-header {
          text-align: center;
          margin-bottom: 2rem;
        }
        
        .success-icon {
          font-size: 3rem;
          color: #48bb78;
          margin-bottom: 1rem;
        }
        
        .upload-info {
          background: #f7fafc;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          padding: 1.5rem;
          margin-bottom: 2rem;
        }
        
        .info-item {
          margin-bottom: 0.75rem;
          color: #4a5568;
        }
        
        .info-item:last-child {
          margin-bottom: 0;
        }
        
        .download-link-section {
          margin-bottom: 2rem;
        }
        
        .link-container {
          display: flex;
          gap: 0.5rem;
        }
        
        .link-input {
          flex: 1;
          font-family: monospace;
          font-size: 0.9rem;
        }
        
        .copy-btn {
          flex-shrink: 0;
          min-width: 100px;
        }
        
        .security-notice {
          background: #fef5e7;
          border: 1px solid #f6ad55;
          border-radius: 8px;
          padding: 1.5rem;
          margin-bottom: 2rem;
        }
        
        .security-notice h3 {
          color: #744210;
          margin-bottom: 1rem;
          font-size: 1rem;
        }
        
        .security-notice ul {
          color: #744210;
          margin: 0;
          padding-left: 1.5rem;
        }
        
        .security-notice li {
          margin-bottom: 0.5rem;
        }
        
        .actions {
          text-align: center;
        }
        
        @media (max-width: 768px) {
          .link-container {
            flex-direction: column;
          }
          
          .copy-btn {
            min-width: auto;
          }
        }
      `}</style>
    </div>
  );
};

export default UploadPage;
