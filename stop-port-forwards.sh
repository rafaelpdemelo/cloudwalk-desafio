#!/bin/bash

# Script para parar port-forwards da aplicação

echo "🛑 Parando port-forwards..."

# Matar port-forwards específicos
pkill -f "kubectl port-forward.*file-sharing-frontend" 2>/dev/null && echo "✅ Port-forward da aplicação parado"
pkill -f "kubectl port-forward.*argocd-server" 2>/dev/null && echo "✅ Port-forward do ArgoCD parado"

# Remover arquivos de PID
rm -f /tmp/file-sharing-app.pid /tmp/argocd.pid 2>/dev/null

echo "✅ Todos os port-forwards foram parados"
