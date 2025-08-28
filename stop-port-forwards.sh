#!/bin/bash

# Script para parar todos os port-forwards

echo "🛑 Parando todos os port-forwards..."

# Parar proxy HTTPS
pkill -f "node /tmp/https-proxy" 2>/dev/null || true

# Parar port-forward HTTP
pkill -f "kubectl port-forward.*8081:80" 2>/dev/null || true

# Parar port-forward ArgoCD
pkill -f "kubectl port-forward.*8443:443" 2>/dev/null || true

# Limpar arquivos temporários
rm -f /tmp/https-proxy.js /tmp/server.crt /tmp/server.key 2>/dev/null || true

echo "✅ Todos os port-forwards parados!"
echo "🧹 Arquivos temporários limpos!"
