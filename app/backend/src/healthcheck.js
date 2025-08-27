const http = require('http');

/**
 * Health check simples para Docker
 * Verifica se o servidor está respondendo
 */
const healthCheck = () => {
  const options = {
    hostname: 'localhost',
    port: process.env.PORT || 3000,
    path: '/health',
    method: 'GET',
    timeout: 2000
  };

  const req = http.request(options, (res) => {
    if (res.statusCode === 200) {
      process.exit(0);
    } else {
      console.error(`Health check falhou: status ${res.statusCode}`);
      process.exit(1);
    }
  });

  req.on('error', (err) => {
    console.error('Health check erro:', err.message);
    process.exit(1);
  });

  req.on('timeout', () => {
    console.error('Health check timeout');
    req.destroy();
    process.exit(1);
  });

  req.end();
};

healthCheck();
