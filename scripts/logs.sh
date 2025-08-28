#!/bin/bash

# Script de Logs - CloudWalk Desafio
# Mostra logs das aplicações

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

# Função para verificar se kubectl está configurado
check_kubectl() {
    if ! kubectl cluster-info &>/dev/null; then
        error "kubectl não está configurado ou cluster não está acessível"
        exit 1
    fi
}

# Função para mostrar logs do frontend
show_frontend_logs() {
    log "Logs do Frontend..."
    
    if kubectl get deployment file-sharing-app-frontend -n "$NAMESPACE" &>/dev/null; then
        echo ""
        echo "=== FRONTEND LOGS ==="
        kubectl logs -n "$NAMESPACE" deployment/file-sharing-app-frontend --tail=50 -f
    else
        warning "Deployment do frontend não encontrado"
    fi
}

# Função para mostrar logs do backend
show_backend_logs() {
    log "Logs do Backend..."
    
    if kubectl get deployment file-sharing-app-backend -n "$NAMESPACE" &>/dev/null; then
        echo ""
        echo "=== BACKEND LOGS ==="
        kubectl logs -n "$NAMESPACE" deployment/file-sharing-app-backend --tail=50 -f
    else
        warning "Deployment do backend não encontrado"
    fi
}

# Função para mostrar logs do ArgoCD
show_argocd_logs() {
    log "Logs do ArgoCD..."
    
    if kubectl get deployment argocd-server -n "$ARGOCD_NAMESPACE" &>/dev/null; then
        echo ""
        echo "=== ARGOCD SERVER LOGS ==="
        kubectl logs -n "$ARGOCD_NAMESPACE" deployment/argocd-server --tail=30
    else
        warning "Deployment do ArgoCD não encontrado"
    fi
    
    if kubectl get deployment argocd-application-controller -n "$ARGOCD_NAMESPACE" &>/dev/null; then
        echo ""
        echo "=== ARGOCD APPLICATION CONTROLLER LOGS ==="
        kubectl logs -n "$ARGOCD_NAMESPACE" deployment/argocd-application-controller --tail=30
    fi
    
    if kubectl get deployment argocd-repo-server -n "$ARGOCD_NAMESPACE" &>/dev/null; then
        echo ""
        echo "=== ARGOCD REPO SERVER LOGS ==="
        kubectl logs -n "$ARGOCD_NAMESPACE" deployment/argocd-repo-server --tail=30
    fi
}

# Função para mostrar logs do ingress
show_ingress_logs() {
    log "Logs do Ingress..."
    
    if kubectl get deployment ingress-nginx-controller -n ingress-nginx &>/dev/null; then
        echo ""
        echo "=== INGRESS NGINX LOGS ==="
        kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=30
    else
        warning "Deployment do Ingress não encontrado"
    fi
}

# Função para mostrar logs de eventos
show_events() {
    log "Eventos do namespace..."
    
    echo ""
    echo "=== EVENTOS DO NAMESPACE $NAMESPACE ==="
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -20
}

# Função para mostrar logs de pods com problemas
show_problematic_pods() {
    log "Verificando pods com problemas..."
    
    echo ""
    echo "=== PODS COM PROBLEMAS ==="
    
    # Pods não rodando
    local not_running=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running --no-headers 2>/dev/null || true)
    if [ -n "$not_running" ]; then
        echo "Pods não rodando:"
        echo "$not_running"
        echo ""
    fi
    
    # Pods com restarts
    local restarted=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | awk '$4 > 0 {print $0}' || true)
    if [ -n "$restarted" ]; then
        echo "Pods com restarts:"
        echo "$restarted"
        echo ""
    fi
    
    # Pods com problemas de readiness
    local not_ready=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | awk '$2 != $3 {print $0}' || true)
    if [ -n "$not_ready" ]; then
        echo "Pods não prontos:"
        echo "$not_ready"
    fi
}

# Função para mostrar logs específicos por pod
show_pod_logs() {
    local pod_name="$1"
    local container_name="${2:-}"
    
    log "Logs do pod: $pod_name"
    
    if kubectl get pod "$pod_name" -n "$NAMESPACE" &>/dev/null; then
        echo ""
        echo "=== LOGS DO POD: $pod_name ==="
        if [ -n "$container_name" ]; then
            kubectl logs -n "$NAMESPACE" "$pod_name" -c "$container_name" --tail=50
        else
            kubectl logs -n "$NAMESPACE" "$pod_name" --tail=50
        fi
    else
        error "Pod $pod_name não encontrado"
    fi
}

# Função para mostrar logs de todos os pods
show_all_pods_logs() {
    log "Logs de todos os pods..."
    
    echo ""
    echo "=== TODOS OS PODS ==="
    kubectl get pods -n "$NAMESPACE" -o wide
    
    echo ""
    echo "=== LOGS DE TODOS OS PODS ==="
    
    # Obter todos os pods
    local pods=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" 2>/dev/null || true)
    
    if [ -n "$pods" ]; then
        echo "$pods" | while read -r pod; do
            if [ -n "$pod" ]; then
                echo ""
                echo "--- POD: $pod ---"
                kubectl logs -n "$NAMESPACE" "$pod" --tail=10 2>/dev/null || echo "  Sem logs disponíveis"
            fi
        done
    else
        warning "Nenhum pod encontrado no namespace $NAMESPACE"
    fi
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  frontend     - Mostra logs do frontend"
    echo "  backend      - Mostra logs do backend"
    echo "  argocd       - Mostra logs do ArgoCD"
    echo "  ingress      - Mostra logs do Ingress"
    echo "  events       - Mostra eventos do namespace"
    echo "  problems     - Mostra pods com problemas"
    echo "  all          - Mostra logs de todos os pods"
    echo "  pod <nome>   - Mostra logs de um pod específico"
    echo "  help         - Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 frontend"
    echo "  $0 backend"
    echo "  $0 pod file-sharing-app-frontend-abc123"
    echo ""
    echo "Para seguir logs em tempo real, use -f:"
    echo "  kubectl logs -n $NAMESPACE deployment/file-sharing-app-frontend -f"
}

# Função principal
main() {
    local option="${1:-}"
    
    echo "📋 Logs do CloudWalk Desafio..."
    echo "==============================="
    
    check_kubectl
    
    case "$option" in
        "frontend")
            show_frontend_logs
            ;;
        "backend")
            show_backend_logs
            ;;
        "argocd")
            show_argocd_logs
            ;;
        "ingress")
            show_ingress_logs
            ;;
        "events")
            show_events
            ;;
        "problems")
            show_problematic_pods
            ;;
        "all")
            show_all_pods_logs
            ;;
        "pod")
            if [ -n "${2:-}" ]; then
                show_pod_logs "$2"
            else
                error "Nome do pod não especificado"
                echo "Uso: $0 pod <nome-do-pod>"
            fi
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            # Mostrar logs principais por padrão
            show_frontend_logs &
            show_backend_logs &
            wait
            ;;
        *)
            error "Opção inválida: $option"
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
