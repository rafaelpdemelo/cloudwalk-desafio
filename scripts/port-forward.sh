#!/bin/bash

# Script de Port-Forward - CloudWalk Desafio
# Configura port-forward para acesso local à aplicação

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis
PROJECT_NAME="file-sharing-app"
NAMESPACE="file-sharing"
ARGOCD_NAMESPACE="argocd"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

# Função para parar port-forwards existentes
stop_existing_forwards() {
    log "Parando port-forwards existentes..."
    
    # Encontrar e matar processos de port-forward
    local pids=$(pgrep -f "kubectl port-forward" || true)
    if [ -n "$pids" ]; then
        echo "$pids" | xargs kill -9 2>/dev/null || true
        success "Port-forwards anteriores parados"
    fi
}

# Função para configurar port-forward da aplicação
setup_app_port_forward() {
    log "Configurando port-forward da aplicação..."
    
    # Verificar se o namespace existe
    if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
        error "Namespace $NAMESPACE não encontrado"
        echo "  Execute: make setup"
        exit 1
    fi
    
    # Verificar se o serviço existe
    if ! kubectl get svc -n "$NAMESPACE" | grep -q "frontend"; then
        error "Serviço frontend não encontrado"
        echo "  Execute: make setup"
        exit 1
    fi
    
    # Configurar port-forward para o frontend (porta 3000)
    log "Iniciando port-forward para frontend (localhost:3000)..."
    kubectl port-forward -n "$NAMESPACE" svc/file-sharing-app-frontend 3000:80 &
    FRONTEND_PID=$!
    
    # Aguardar um pouco para o port-forward estar pronto
    sleep 2
    
    # Verificar se o processo está rodando
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        success "Port-forward do frontend iniciado (PID: $FRONTEND_PID)"
    else
        error "Falha ao iniciar port-forward do frontend"
        exit 1
    fi
    
    # Salvar PID em arquivo para referência futura
    echo $FRONTEND_PID > "$PROJECT_ROOT/scripts/.port-forward-frontend.pid"
}

# Função para configurar port-forward do backend
setup_backend_port_forward() {
    log "Configurando port-forward do backend..."
    
    # Verificar se o serviço backend existe
    if kubectl get svc -n "$NAMESPACE" | grep -q "backend"; then
        # Configurar port-forward para o backend (porta 3001)
        log "Iniciando port-forward para backend (localhost:3001)..."
        kubectl port-forward -n "$NAMESPACE" svc/file-sharing-app-backend 3001:3000 &
        BACKEND_PID=$!
        
        # Aguardar um pouco para o port-forward estar pronto
        sleep 2
        
        # Verificar se o processo está rodando
        if kill -0 $BACKEND_PID 2>/dev/null; then
            success "Port-forward do backend iniciado (PID: $BACKEND_PID)"
        else
            warning "Falha ao iniciar port-forward do backend"
        fi
        
        # Salvar PID em arquivo para referência futura
        echo $BACKEND_PID > "$PROJECT_ROOT/scripts/.port-forward-backend.pid"
    else
        warning "Serviço backend não encontrado"
    fi
}

# Função para configurar port-forward do ArgoCD
setup_argocd_port_forward() {
    log "Configurando port-forward do ArgoCD..."
    
    # Verificar se o namespace do ArgoCD existe
    if kubectl get namespace "$ARGOCD_NAMESPACE" &>/dev/null; then
        # Configurar port-forward para o ArgoCD (porta 8080)
        log "Iniciando port-forward para ArgoCD (localhost:8080)..."
        kubectl port-forward -n "$ARGOCD_NAMESPACE" svc/argocd-server 8080:443 &
        ARGOCD_PID=$!
        
        # Aguardar um pouco para o port-forward estar pronto
        sleep 2
        
        # Verificar se o processo está rodando
        if kill -0 $ARGOCD_PID 2>/dev/null; then
            success "Port-forward do ArgoCD iniciado (PID: $ARGOCD_PID)"
        else
            warning "Falha ao iniciar port-forward do ArgoCD"
        fi
        
        # Salvar PID em arquivo para referência futura
        echo $ARGOCD_PID > "$PROJECT_ROOT/scripts/.port-forward-argocd.pid"
    else
        warning "Namespace do ArgoCD não encontrado"
    fi
}

# Função para configurar port-forward do Ingress Controller (HTTPS)
setup_ingress_port_forward() {
    log "Configurando port-forward do Ingress Controller (HTTPS)..."
    
    # Verificar se o namespace do ingress-nginx existe
    if kubectl get namespace "ingress-nginx" &>/dev/null; then
        # Configurar port-forward para o Ingress Controller (porta 8443)
        log "Iniciando port-forward para Ingress Controller (localhost:8443)..."
        kubectl port-forward -n "ingress-nginx" svc/ingress-nginx-controller 8443:443 &
        INGRESS_PID=$!
        
        # Aguardar um pouco para o port-forward estar pronto
        sleep 2
        
        # Verificar se o processo está rodando
        if kill -0 $INGRESS_PID 2>/dev/null; then
            success "Port-forward do Ingress Controller iniciado (PID: $INGRESS_PID)"
        else
            warning "Falha ao iniciar port-forward do Ingress Controller"
        fi
        
        # Salvar PID em arquivo para referência futura
        echo $INGRESS_PID > "$PROJECT_ROOT/scripts/.port-forward-ingress.pid"
    else
        warning "Namespace do ingress-nginx não encontrado"
    fi
}

# Função para mostrar informações de acesso
show_access_info() {
    log "Informações de acesso..."
    
    echo ""
    echo "=== ACESSO À APLICAÇÃO ==="
    echo "🌐 Frontend: http://localhost:3000"
    echo "🔗 Backend API: http://localhost:3001"
    echo "🔒 Frontend (HTTPS): https://localhost:8443 (certificado CloudWalk self-signed)"
    echo "📊 ArgoCD: https://localhost:8080"
    echo ""
    echo "=== CREDENCIAIS ARGOCD ==="
    echo "👤 Usuário: admin"
    echo "🔑 Senha: $(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "Não disponível")"
    echo ""
    echo "=== DOMÍNIO LOCAL ==="
    echo "🌍 file-sharing.local (se configurado no /etc/hosts)"
    echo ""
    echo "=== PIDs DOS PORT-FORWARDS ==="
    if [ -f "$PROJECT_ROOT/scripts/.port-forward-frontend.pid" ]; then
        echo "Frontend: $(cat "$PROJECT_ROOT/scripts/.port-forward-frontend.pid")"
    fi
    if [ -f "$PROJECT_ROOT/scripts/.port-forward-backend.pid" ]; then
        echo "Backend: $(cat "$PROJECT_ROOT/scripts/.port-forward-backend.pid")"
    fi
    if [ -f "$PROJECT_ROOT/scripts/.port-forward-argocd.pid" ]; then
        echo "ArgoCD: $(cat "$PROJECT_ROOT/scripts/.port-forward-argocd.pid")"
    fi
    if [ -f "$PROJECT_ROOT/scripts/.port-forward-ingress.pid" ]; then
        echo "Ingress: $(cat "$PROJECT_ROOT/scripts/.port-forward-ingress.pid")"
    fi
    echo ""
    echo "💡 Para parar os port-forwards: make stop-port-forwards"
    echo "💡 Para verificar status: make status"
}

# Função para configurar trap para limpeza
setup_cleanup_trap() {
    # Função de limpeza
    cleanup() {
        log "Limpando port-forwards..."
        stop_existing_forwards
        rm -f "$PROJECT_ROOT/scripts/.port-forward-*.pid"
        exit 0
    }
    
    # Configurar trap para SIGINT e SIGTERM
    trap cleanup SIGINT SIGTERM
    
    success "Trap configurado - Ctrl+C para parar"
}

# Função principal
main() {
    echo "🔗 Configurando port-forward para CloudWalk Desafio..."
    echo "====================================================="
    
    # Verificar se kubectl está configurado
    if ! kubectl cluster-info &>/dev/null; then
        error "kubectl não está configurado ou cluster não está acessível"
        exit 1
    fi
    
    # Parar port-forwards existentes
    stop_existing_forwards
    
    # Configurar trap para limpeza
    setup_cleanup_trap
    
    # Configurar port-forwards
    setup_app_port_forward
    setup_backend_port_forward
    setup_argocd_port_forward
    setup_ingress_port_forward
    
    # Mostrar informações de acesso
    show_access_info
    
    # Manter script rodando
    log "Port-forwards ativos. Pressione Ctrl+C para parar..."
    while true; do
        sleep 10
        
        # Verificar se os processos ainda estão rodando
        if [ -f "$PROJECT_ROOT/scripts/.port-forward-frontend.pid" ]; then
            local frontend_pid=$(cat "$PROJECT_ROOT/scripts/.port-forward-frontend.pid")
            if ! kill -0 $frontend_pid 2>/dev/null; then
                warning "Port-forward do frontend parou inesperadamente"
            fi
        fi
        
        if [ -f "$PROJECT_ROOT/scripts/.port-forward-backend.pid" ]; then
            local backend_pid=$(cat "$PROJECT_ROOT/scripts/.port-forward-backend.pid")
            if ! kill -0 $backend_pid 2>/dev/null; then
                warning "Port-forward do backend parou inesperadamente"
            fi
        fi
        
        if [ -f "$PROJECT_ROOT/scripts/.port-forward-argocd.pid" ]; then
            local argocd_pid=$(cat "$PROJECT_ROOT/scripts/.port-forward-argocd.pid")
            if ! kill -0 $argocd_pid 2>/dev/null; then
                warning "Port-forward do ArgoCD parou inesperadamente"
            fi
        fi
    done
}

# Executar função principal
main "$@"
