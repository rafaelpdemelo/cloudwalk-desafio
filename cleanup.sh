#!/bin/bash

# CloudWalk File Sharing App - Cleanup Script
# Este script remove todo o ambiente configurado

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
NAMESPACE="file-sharing"
ARGOCD_NAMESPACE="argocd"
DOMAIN="file-sharing.local"

echo -e "${RED}🧹 Limpando CloudWalk File Sharing App${NC}"
echo -e "${RED}====================================${NC}"

# Função para mostrar status
show_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

# Função para mostrar sucesso
show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Função para mostrar erro
show_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para mostrar aviso
show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Confirmar limpeza
confirm_cleanup() {
    echo -e "${YELLOW}⚠️  Esta operação irá remover:${NC}"
    echo "   - Namespaces: $NAMESPACE, $ARGOCD_NAMESPACE"
    echo "   - Imagens Docker locais"
    echo "   - Certificados gerados"
    echo "   - Entrada no /etc/hosts"
    echo "   - Minikube cluster (opcional)"
    echo ""
    
    read -p "Continuar com a limpeza? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Limpeza cancelada.${NC}"
        exit 0
    fi
}

# Remover aplicação do ArgoCD
remove_argocd_app() {
    show_status "Removendo aplicação do ArgoCD..."
    
    if kubectl get application file-sharing-app -n $ARGOCD_NAMESPACE &> /dev/null; then
        kubectl delete application file-sharing-app -n $ARGOCD_NAMESPACE
        show_success "Aplicação ArgoCD removida"
    else
        show_warning "Aplicação ArgoCD não encontrada"
    fi
}

# Remover namespaces
remove_namespaces() {
    show_status "Removendo namespaces..."
    
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        kubectl delete namespace $NAMESPACE --ignore-not-found=true
        show_success "Namespace $NAMESPACE removido"
    fi
    
    if kubectl get namespace $ARGOCD_NAMESPACE &> /dev/null; then
        kubectl delete namespace $ARGOCD_NAMESPACE --ignore-not-found=true
        show_success "Namespace $ARGOCD_NAMESPACE removido"
    fi
}

# Remover imagens Docker
remove_docker_images() {
    show_status "Removendo imagens Docker..."
    
    local images=("file-sharing-backend:latest" "file-sharing-frontend:latest" "file-sharing-proxy:latest")
    
    for image in "${images[@]}"; do
        if docker images -q "$image" &> /dev/null; then
            docker rmi "$image" --force &> /dev/null || true
            show_success "Imagem $image removida"
        fi
    done
}

# Remover certificados
remove_certificates() {
    show_status "Removendo certificados..."
    
    if [ -d "certs" ]; then
        rm -rf certs/
        show_success "Certificados removidos"
    else
        show_warning "Diretório de certificados não encontrado"
    fi
}

# Remover entrada do /etc/hosts
remove_hosts_entry() {
    show_status "Removendo entrada do /etc/hosts..."
    
    if grep -q "$DOMAIN" /etc/hosts 2>/dev/null; then
        sudo sed -i '' "/$DOMAIN/d" /etc/hosts 2>/dev/null || true
        show_success "Entrada do /etc/hosts removida"
    else
        show_warning "Entrada do /etc/hosts não encontrada"
    fi
}

# Limpar volumes persistentes
cleanup_volumes() {
    show_status "Limpando volumes persistentes..."
    
    # Remover PVCs órfãs
    kubectl get pvc --all-namespaces --no-headers | grep -E "(file-sharing|Terminating)" | awk '{print $1, $2}' | while read namespace pvc; do
        kubectl delete pvc "$pvc" -n "$namespace" --ignore-not-found=true &> /dev/null || true
    done
    
    show_success "Volumes limpos"
}

# Parar e remover Minikube (opcional)
cleanup_minikube() {
    echo ""
    read -p "Remover o cluster Minikube completamente? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_status "Parando e removendo Minikube..."
        
        minikube stop &> /dev/null || true
        minikube delete &> /dev/null || true
        
        show_success "Minikube removido"
    else
        show_warning "Minikube mantido (pode conter recursos órfãos)"
    fi
}

# Limpar arquivos temporários
cleanup_temp_files() {
    show_status "Limpando arquivos temporários..."
    
    # Remover logs
    rm -rf logs/ 2>/dev/null || true
    
    # Remover cache do npm/yarn
    rm -rf app/backend/node_modules/ 2>/dev/null || true
    rm -rf app/frontend/node_modules/ 2>/dev/null || true
    rm -rf app/frontend/dist/ 2>/dev/null || true
    
    # Remover arquivos de build
    find . -name "*.log" -delete 2>/dev/null || true
    find . -name ".DS_Store" -delete 2>/dev/null || true
    
    show_success "Arquivos temporários limpos"
}

# Verificar recursos restantes
check_remaining_resources() {
    show_status "Verificando recursos restantes..."
    
    local remaining=0
    
    # Verificar namespaces
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        show_warning "Namespace $NAMESPACE ainda existe"
        remaining=$((remaining + 1))
    fi
    
    # Verificar imagens Docker
    local images=$(docker images -q file-sharing-* 2>/dev/null | wc -l)
    if [ "$images" -gt 0 ]; then
        show_warning "$images imagens Docker ainda existem"
        remaining=$((remaining + 1))
    fi
    
    # Verificar entrada no hosts
    if grep -q "$DOMAIN" /etc/hosts 2>/dev/null; then
        show_warning "Entrada no /etc/hosts ainda existe"
        remaining=$((remaining + 1))
    fi
    
    if [ $remaining -eq 0 ]; then
        show_success "Todos os recursos foram removidos"
    else
        show_warning "$remaining recursos ainda existem"
    fi
}

# Mostrar resumo final
show_cleanup_summary() {
    echo -e "\n${GREEN}🎉 Limpeza concluída!${NC}\n"
    
    echo -e "${BLUE}📋 Resumo da Limpeza:${NC}"
    echo -e "${BLUE}====================${NC}"
    echo "✅ Namespaces removidos"
    echo "✅ Imagens Docker removidas"
    echo "✅ Certificados removidos"
    echo "✅ Entrada do /etc/hosts removida"
    echo "✅ Volumes persistentes limpos"
    echo "✅ Arquivos temporários limpos"
    
    echo -e "\n${BLUE}🔧 Para recriar o ambiente:${NC}"
    echo "   ./setup.sh"
}

# Função principal
main() {
    echo -e "${BLUE}Iniciando limpeza do CloudWalk File Sharing App...${NC}\n"
    
    confirm_cleanup
    
    remove_argocd_app
    remove_namespaces
    cleanup_volumes
    remove_docker_images
    remove_certificates
    remove_hosts_entry
    cleanup_temp_files
    cleanup_minikube
    check_remaining_resources
    show_cleanup_summary
    
    echo -e "\n${GREEN}🧹 Limpeza concluída!${NC}"
}

# Tratamento de erro
trap 'show_error "Erro durante a limpeza. Alguns recursos podem não ter sido removidos."' ERR

# Executar função principal
main "$@"
