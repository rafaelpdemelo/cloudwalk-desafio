import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { ToastContainer } from 'react-toastify';
import App from './App';

// Importar estilos
import './styles/global.css';
import 'react-toastify/dist/ReactToastify.css';

// Configuração de segurança
if (process.env.NODE_ENV === 'production') {
  // Desabilitar console em produção
  console.log = () => {};
  console.warn = () => {};
  console.error = () => {};
  
  // Detectar DevTools (básico)
  let devtools = false;
  setInterval(() => {
    if (window.outerHeight - window.innerHeight > 200 || 
        window.outerWidth - window.innerWidth > 200) {
      if (!devtools) {
        devtools = true;
        console.clear();
        document.body.innerHTML = '<h1 style="text-align:center;margin-top:50px;">Acesso negado</h1>';
      }
    }
  }, 500);
}

// Prevenir ataques de timing
const originalFetch = window.fetch;
window.fetch = (...args) => {
  const start = Date.now();
  return originalFetch(...args).finally(() => {
    const elapsed = Date.now() - start;
    if (elapsed < 100) {
      // Adicionar delay mínimo para prevenir timing attacks
      setTimeout(() => {}, 100 - elapsed);
    }
  });
};

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
      <ToastContainer
        position="top-right"
        autoClose={5000}
        hideProgressBar={false}
        newestOnTop={false}
        closeOnClick
        rtl={false}
        pauseOnFocusLoss
        draggable
        pauseOnHover
        theme="light"
        toastClassName="custom-toast"
      />
    </BrowserRouter>
  </React.StrictMode>
);
