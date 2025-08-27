import { useEffect } from 'react';

/**
 * Hook para proteção básica contra CSRF
 */
export const useCSRFProtection = () => {
  useEffect(() => {
    // Gerar token CSRF simples
    const generateCSRFToken = () => {
      return btoa(Math.random().toString()).substr(10, 5);
    };

    // Armazenar token no sessionStorage
    if (!sessionStorage.getItem('csrf_token')) {
      sessionStorage.setItem('csrf_token', generateCSRFToken());
    }

    // Interceptar requests fetch para adicionar token CSRF
    const originalFetch = window.fetch;
    window.fetch = function(...args) {
      const [url, options = {}] = args;
      
      // Adicionar token CSRF em requests que modificam dados
      if (options.method && ['POST', 'PUT', 'DELETE', 'PATCH'].includes(options.method.toUpperCase())) {
        options.headers = {
          ...options.headers,
          'X-CSRF-Token': sessionStorage.getItem('csrf_token')
        };
      }
      
      return originalFetch.apply(this, [url, options]);
    };

    // Cleanup
    return () => {
      window.fetch = originalFetch;
    };
  }, []);
};

export default useCSRFProtection;
