#!/bin/bash

# Script para iniciar proxy HTTPS com certificado self-signed
# Gerado pelo setup.sh

set -e

echo "🔧 Iniciando proxy HTTPS com certificado self-signed..."

# Verificar se os certificados existem
if [ ! -f "certs/server.crt" ] || [ ! -f "certs/server.key" ]; then
    echo "❌ Certificados não encontrados. Execute o setup.sh primeiro."
    exit 1
fi

# Copiar certificados para /tmp
cp certs/server.crt /tmp/
cp certs/server.key /tmp/

# Criar script de proxy Node.js
cat > /tmp/https-proxy.js << 'PROXY_EOF'
const https = require('https');
const http = require('http');
const fs = require('fs');

const options = {
  key: fs.readFileSync('/tmp/server.key'),
  cert: fs.readFileSync('/tmp/server.crt')
};

const server = https.createServer(options, (req, res) => {
  const proxyReq = http.request({
    hostname: 'localhost',
    port: 8081,
    path: req.url,
    method: req.method,
    headers: req.headers
  }, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  req.pipe(proxyReq);
});

server.listen(8080, () => {
  console.log('🔐 HTTPS Proxy running on https://localhost:8080');
  console.log('📜 Using self-signed certificate from setup.sh');
  console.log('🎯 Certificate: CN=file-sharing.local, O=CloudWalk');
});
PROXY_EOF

# Iniciar port-forward HTTP (se não estiver rodando)
if ! pgrep -f "kubectl port-forward.*8081:80" > /dev/null; then
    echo "🔌 Iniciando port-forward HTTP..."
    kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80 > /dev/null 2>&1 &
    sleep 5
fi

# Iniciar proxy HTTPS
echo "🚀 Iniciando proxy HTTPS..."
node /tmp/https-proxy.js &

echo "✅ Proxy HTTPS iniciado!"
echo "🌐 Acesse: https://localhost:8080"
echo "🔐 Certificado: CN=file-sharing.local, O=CloudWalk"
echo ""
echo "💡 Para parar: pkill -f 'node /tmp/https-proxy.js'"
