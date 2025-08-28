#!/bin/bash

echo "🛑 Parando proxy HTTPS..."

# Parar proxy Node.js
pkill -f "node /tmp/https-proxy.js" 2>/dev/null || true

# Parar port-forward HTTP
pkill -f "kubectl port-forward.*8081:80" 2>/dev/null || true

# Limpar arquivos temporários
rm -f /tmp/https-proxy.js /tmp/server.crt /tmp/server.key 2>/dev/null || true

echo "✅ Proxy HTTPS parado!"
echo "�� Arquivos temporários limpos!"
