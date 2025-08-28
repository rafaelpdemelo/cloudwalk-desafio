#!/bin/bash

# Script para Parar Port-Forwards - CloudWalk Desafio
# Para todos os port-forwards ativos

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis
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

# Função para parar port-forwards por PID
stop_port_forwards_by_pid() {
    log "Parando port-forwards por PID..."
    
    local stopped_count=0
    
    # Parar frontend
    if [ -f "$PROJECT_ROOT/scripts/.port-forward-frontend.pid" ]; then
        local frontend_pid=$(cat "$PROJECT_ROOT/scripts/.port-forward-frontend.pid")
        if kill -0 $frontend_pid 2>/dev/null; then
            kill -9 $frontend_pid 2>/dev/null || true
            success "Port-forward do frontend parado (PID: $frontend_pid)"
            ((stopped_count++))
        fi
        rm -f "$PROJECT_ROOT/scripts/.port-forward-frontend.pid"
    fi
    
    # Parar backend
    if [ -f "$PROJECT_ROOT/scripts/.port-forward-backend.pid" ]; then
        local backend_pid=$(cat "$PROJECT_ROOT/scripts/.port-forward-backend.pid")
        if kill -0 $backend_pid 2>/dev/null; then
            kill -9 $backend_pid 2>/dev/null || true
            success "Port-forward do backend parado (PID: $backend_pid)"
            ((stopped_count++))
        fi
        rm -f "$PROJECT_ROOT/scripts/.port-forward-backend.pid"
    fi
    
    # Parar ArgoCD
    if [ -f "$PROJECT_ROOT/scripts/.port-forward-argocd.pid" ]; then
        local argocd_pid=$(cat "$PROJECT_ROOT/scripts/.port-forward-argocd.pid")
        if kill -0 $argocd_pid 2>/dev/null; then
            kill -9 $argocd_pid 2>/dev/null || true
            success "Port-forward do ArgoCD parado (PID: $argocd_pid)"
            ((stopped_count++))
        fi
        rm -f "$PROJECT_ROOT/scripts/.port-forward-argocd.pid"
    fi
    
    if [ $stopped_count -gt 0 ]; then
        success "$stopped_count port-forward(s) parado(s)"
    else
        warning "Nenhum port-forward ativo encontrado"
    fi
}

# Função para parar port-forwards por processo
stop_port_forwards_by_process() {
    log "Parando port-forwards por processo..."
    
    # Encontrar todos os processos kubectl port-forward
    local pids=$(pgrep -f "kubectl port-forward" || true)
    
    if [ -n "$pids" ]; then
        echo "$pids" | while read -r pid; do
            if kill -0 $pid 2>/dev/null; then
                kill -9 $pid 2>/dev/null || true
                success "Port-forward parado (PID: $pid)"
            fi
        done
        success "Todos os port-forwards kubectl parados"
    else
        warning "Nenhum processo kubectl port-forward encontrado"
    fi
}

# Função para verificar portas em uso
check_ports_in_use() {
    log "Verificando portas em uso..."
    
    local ports=("3000" "3001" "8080")
    local ports_in_use=()
    
    for port in "${ports[@]}"; do
        if lsof -i :$port &>/dev/null; then
            ports_in_use+=("$port")
        fi
    done
    
    if [ ${#ports_in_use[@]} -gt 0 ]; then
        warning "Portas ainda em uso: ${ports_in_use[*]}"
        echo "  Para verificar processos: lsof -i :<porta>"
        echo "  Para matar processo: kill -9 <PID>"
    else
        success "Todas as portas estão livres"
    fi
}

# Função para limpar arquivos temporários
cleanup_temp_files() {
    log "Limpando arquivos temporários..."
    
    # Remover arquivos de PID
    rm -f "$PROJECT_ROOT/scripts/.port-forward-*.pid"
    
    success "Arquivos temporários limpos"
}

# Função principal
main() {
    echo "🛑 Parando port-forwards do CloudWalk Desafio..."
    echo "================================================"
    
    # Parar port-forwards por PID
    stop_port_forwards_by_pid
    
    # Parar port-forwards por processo (fallback)
    stop_port_forwards_by_process
    
    # Verificar portas em uso
    check_ports_in_use
    
    # Limpar arquivos temporários
    cleanup_temp_files
    
    success "Todos os port-forwards foram parados!"
    echo ""
    echo "💡 Para reiniciar port-forwards: make port-forward"
    echo "💡 Para verificar status: make status"
}

# Executar função principal
main "$@"
