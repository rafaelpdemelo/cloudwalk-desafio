#!/bin/bash

# Script de Cleanup - CloudWalk Desafio
# Remove completamente o ambiente: aplicação + ArgoCD + minikube

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
MINIKUBE_PROFILE="cloudwalk-desafio"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Função para parar port-forwards
stop_port_forwards() {
    log "Parando port-forwards ativos..."
    
    # Encontrar e matar processos de port-forward
    local pids=$(pgrep -f "kubectl port-forward" || true)
    if [ -n "$pids" ]; then
        echo "$pids" | xargs kill -9 2>/dev/null || true
        success "Port-forwards parados"
    else
        warning "Nenhum port-forward ativo encontrado"
    fi
}

# Função para remover aplicação
remove_application() {
    log "Removendo aplicação..."
    
    # Remover aplicação ArgoCD
    if kubectl get application file-sharing-app -n "$ARGOCD_NAMESPACE" &>/dev/null; then
        kubectl delete application file-sharing-app -n "$ARGOCD_NAMESPACE"
        success "Aplicação ArgoCD removida"
    fi
    
    # Remover projeto ArgoCD
    if kubectl get appproject file-sharing-project -n "$ARGOCD_NAMESPACE" &>/dev/null; then
        kubectl delete appproject file-sharing-project -n "$ARGOCD_NAMESPACE"
        success "Projeto ArgoCD removido"
    fi
    
    # Remover namespace da aplicação
    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
        kubectl delete namespace "$NAMESPACE"
        success "Namespace da aplicação removido"
    fi
}

# Função para remover ArgoCD
remove_argocd() {
    log "Removendo ArgoCD..."
    
    if kubectl get namespace "$ARGOCD_NAMESPACE" &>/dev/null; then
        # Remover ArgoCD
        kubectl delete -n "$ARGOCD_NAMESPACE" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        # Aguardar remoção completa
        log "Aguardando remoção do ArgoCD..."
        kubectl wait --for=delete namespace/"$ARGOCD_NAMESPACE" --timeout=300s || true
        
        success "ArgoCD removido"
    else
        warning "ArgoCD não encontrado"
    fi
}

# Função para parar minikube
stop_minikube() {
    log "Parando cluster Minikube..."
    
    if minikube status --profile="$MINIKUBE_PROFILE" | grep -q "Running"; then
        minikube stop --profile="$MINIKUBE_PROFILE"
        success "Minikube parado"
    else
        warning "Minikube não está rodando"
    fi
}

# Função para deletar minikube
delete_minikube() {
    log "Deletando cluster Minikube..."
    
    if minikube status --profile="$MINIKUBE_PROFILE" &>/dev/null; then
        minikube delete --profile="$MINIKUBE_PROFILE"
        success "Minikube deletado"
    else
        warning "Minikube não encontrado"
    fi
}

# Função para limpar certificados
cleanup_certs() {
    log "Limpando certificados..."
    
    if [ -d "$PROJECT_ROOT/scripts/certs" ]; then
        rm -rf "$PROJECT_ROOT/scripts/certs"
        success "Certificados removidos"
    else
        warning "Diretório de certificados não encontrado"
    fi
}

# Função para limpar hosts local
cleanup_hosts() {
    log "Limpando hosts local..."
    
    if grep -q "file-sharing.local" /etc/hosts; then
        # Remover linha específica do /etc/hosts
        sudo sed -i.bak '/file-sharing\.local/d' /etc/hosts
        success "Entrada file-sharing.local removida do /etc/hosts"
    else
        warning "Entrada file-sharing.local não encontrada no /etc/hosts"
    fi
}

# Função para limpar contexto kubectl
cleanup_kubectl_context() {
    log "Limpando contexto kubectl..."
    
    # Remover contexto do minikube se existir
    if kubectl config get-contexts | grep -q "$MINIKUBE_PROFILE"; then
        kubectl config delete-context "$MINIKUBE_PROFILE"
        success "Contexto kubectl removido"
    fi
    
    # Remover cluster do minikube se existir
    if kubectl config get-clusters | grep -q "$MINIKUBE_PROFILE"; then
        kubectl config delete-cluster "$MINIKUBE_PROFILE"
        success "Cluster kubectl removido"
    fi
    
    # Remover usuário do minikube se existir
    if kubectl config get-users | grep -q "$MINIKUBE_PROFILE"; then
        kubectl config delete-user "$MINIKUBE_PROFILE"
        success "Usuário kubectl removido"
    fi
}

# Função para limpar dados persistentes
cleanup_persistent_data() {
    log "Limpando dados persistentes..."
    
    # Remover volumes persistentes se existirem
    local pvs=$(kubectl get pv -o name 2>/dev/null | grep "$PROJECT_NAME" || true)
    if [ -n "$pvs" ]; then
        echo "$pvs" | xargs kubectl delete
        success "Volumes persistentes removidos"
    fi
    
    # Remover storage classes se existirem
    local scs=$(kubectl get sc -o name 2>/dev/null | grep "$PROJECT_NAME" || true)
    if [ -n "$scs" ]; then
        echo "$scs" | xargs kubectl delete
        success "Storage classes removidos"
    fi
}

# Função para verificar limpeza
verify_cleanup() {
    log "Verificando limpeza..."
    
    echo ""
    echo "=== VERIFICAÇÃO DE LIMPEZA ==="
    
    # Verificar se minikube foi removido
    if ! minikube status --profile="$MINIKUBE_PROFILE" &>/dev/null; then
        success "✓ Minikube removido"
    else
        error "✗ Minikube ainda existe"
    fi
    
    # Verificar se contextos kubectl foram removidos
    if ! kubectl config get-contexts | grep -q "$MINIKUBE_PROFILE"; then
        success "✓ Contextos kubectl removidos"
    else
        error "✗ Contextos kubectl ainda existem"
    fi
    
    # Verificar se certificados foram removidos
    if [ ! -d "$PROJECT_ROOT/scripts/certs" ]; then
        success "✓ Certificados removidos"
    else
        error "✗ Certificados ainda existem"
    fi
    
    # Verificar se hosts local foi limpo
    if ! grep -q "file-sharing.local" /etc/hosts; then
        success "✓ Hosts local limpo"
    else
        warning "⚠ Hosts local ainda contém entradas (verificar manualmente)"
    fi
    
    success "Limpeza concluída com sucesso!"
}

# Função principal
main() {
    echo "🧹 Iniciando cleanup do CloudWalk Desafio..."
    echo "============================================="
    
    # Confirmar com o usuário
    echo ""
    echo "⚠️  ATENÇÃO: Esta operação irá remover COMPLETAMENTE o ambiente!"
    echo "   - Cluster Minikube"
    echo "   - ArgoCD"
    echo "   - Aplicação"
    echo "   - Certificados"
    echo "   - Dados persistentes"
    echo ""
    read -p "Tem certeza que deseja continuar? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operação cancelada pelo usuário"
        exit 0
    fi
    
    stop_port_forwards
    remove_application
    remove_argocd
    cleanup_persistent_data
    stop_minikube
    delete_minikube
    cleanup_certs
    cleanup_hosts
    cleanup_kubectl_context
    verify_cleanup
    
    echo ""
    echo "🎉 Ambiente completamente limpo!"
    echo "Para recriar o ambiente, execute: make setup"
}

# Executar função principal
main "$@"
