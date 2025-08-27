import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { toast } from 'react-toastify';

// Páginas
import HomePage from './pages/HomePage';
import UploadPage from './pages/UploadPage';
import DownloadPage from './pages/DownloadPage';
import NotFoundPage from './pages/NotFoundPage';

// Componentes
import Header from './components/Header';
import Footer from './components/Footer';

// Hooks de segurança
import { useSecurityHeaders } from './hooks/useSecurityHeaders';
import { useCSRFProtection } from './hooks/useCSRFProtection';

function App() {
  // Aplicar headers de segurança
  useSecurityHeaders();
  
  // Proteger contra CSRF
  useCSRFProtection();

  // Detectar tentativas de manipulação do DOM
  React.useEffect(() => {
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'childList') {
          // Verificar se scripts maliciosos foram injetados
          const addedNodes = Array.from(mutation.addedNodes);
          addedNodes.forEach((node) => {
            if (node.tagName === 'SCRIPT' && !node.src.startsWith(window.location.origin)) {
              console.warn('Script suspeito detectado');
              node.remove();
              toast.error('Tentativa de injeção de script detectada e bloqueada');
            }
          });
        }
      });
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });

    return () => observer.disconnect();
  }, []);

  // Error Boundary básico
  React.useEffect(() => {
    const handleError = (event) => {
      console.error('Erro global capturado:', event.error);
      toast.error('Ocorreu um erro inesperado');
    };

    window.addEventListener('error', handleError);
    return () => window.removeEventListener('error', handleError);
  }, []);

  return (
    <div className="app">
      <Header />
      
      <main className="main-content">
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/upload" element={<UploadPage />} />
          <Route path="/download/:token" element={<DownloadPage />} />
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </main>
      
      <Footer />
    </div>
  );
}

export default App;
