import { useEffect } from 'react';

/**
 * Hook para aplicar headers de segurança no frontend
 */
export const useSecurityHeaders = () => {
  useEffect(() => {
    // Configurar Content Security Policy via meta tag
    const cspMeta = document.createElement('meta');
    cspMeta.httpEquiv = 'Content-Security-Policy';
    cspMeta.content = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' wss: https:; font-src 'self'; object-src 'none'; media-src 'self'; frame-src 'none';";
    document.head.appendChild(cspMeta);

    // Configurar outros headers de segurança
    const xFrameOptions = document.createElement('meta');
    xFrameOptions.httpEquiv = 'X-Frame-Options';
    xFrameOptions.content = 'SAMEORIGIN';
    document.head.appendChild(xFrameOptions);

    const xContentType = document.createElement('meta');
    xContentType.httpEquiv = 'X-Content-Type-Options';
    xContentType.content = 'nosniff';
    document.head.appendChild(xContentType);

    return () => {
      // Cleanup se necessário
      if (cspMeta.parentNode) {
        cspMeta.parentNode.removeChild(cspMeta);
      }
      if (xFrameOptions.parentNode) {
        xFrameOptions.parentNode.removeChild(xFrameOptions);
      }
      if (xContentType.parentNode) {
        xContentType.parentNode.removeChild(xContentType);
      }
    };
  }, []);
};

export default useSecurityHeaders;
