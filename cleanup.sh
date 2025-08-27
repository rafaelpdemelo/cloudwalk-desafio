#!/bin/bash

# CloudWalk File Sharing App - Cleanup COMPLETO
# Este script remove ABSOLUTAMENTE TUDO do ambiente

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

echo -e "${RED}🧹 LIMPEZA COMPLETA - CloudWalk File Sharing App${NC}"
echo -e "${RED}=================================================${NC}"

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

# Confirmar limpeza TOTAL
confirm_total_cleanup() {
    echo -e "${RED}⚠️  ATENÇÃO: LIMPEZA TOTAL E IRREVERSÍVEL!${NC}"
    echo -e "${YELLOW}Esta operação irá remover TUDO:${NC}"
    echo "   💥 TODOS os namespaces Kubernetes"
    echo "   💥 TODAS as imagens Docker (locais e personalizadas)"
    echo "   💥 TODO o cluster Minikube"
    echo "   💥 TODOS os certificados gerados"
    echo "   💥 TODAS as entradas do /etc/hosts"
    echo "   💥 TODOS os arquivos temporários"
    echo "   💥 TODOS os node_modules"
    echo "   💥 TODOS os volumes e dados"
    echo "   💥 TODOS os processos port-forward"
    echo ""
    echo -e "${RED}🚨 IMPOSSÍVEL REVERTER ESTA OPERAÇÃO! 🚨${NC}"
    echo ""
    
    read -p "Continuar com a DESTRUIÇÃO TOTAL? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}❌ Limpeza cancelada.${NC}"
        exit 0
    fi
    
    echo -e "${RED}💥 INICIANDO DESTRUIÇÃO TOTAL!${NC}\n"
}

# Parar TODOS os processos port-forward
kill_all_port_forwards() {
    show_status "Matando TODOS os processos port-forward..."
    
    # Matar por PIDs salvos
    if [ -f /tmp/file-sharing-app.pid ]; then
        kill $(cat /tmp/file-sharing-app.pid) 2>/dev/null || true
        rm -f /tmp/file-sharing-app.pid
    fi
    
    if [ -f /tmp/argocd.pid ]; then
        kill $(cat /tmp/argocd.pid) 2>/dev/null || true
        rm -f /tmp/argocd.pid
    fi
    
    # Matar TODOS os kubectl port-forward
    pkill -f "kubectl port-forward" 2>/dev/null || true
    
    # Matar processos na porta 8080 e 8443
    lsof -ti:8080 | xargs kill -9 2>/dev/null || true
    lsof -ti:8443 | xargs kill -9 2>/dev/null || true
    
    show_success "Todos os port-forwards mortos"
}

# Destruir COMPLETAMENTE o Minikube
destroy_minikube_completely() {
    show_status "🔥 DESTRUINDO Minikube COMPLETAMENTE..."
    
    # Parar todos os clusters minikube
    minikube stop --all 2>/dev/null || true
    
    # Deletar TODOS os clusters
    minikube delete --all --purge 2>/dev/null || true
    
    # Remover cache e configurações do minikube
    rm -rf ~/.minikube 2>/dev/null || true
    
    # Limpar contextos do kubectl relacionados ao minikube
    kubectl config get-contexts -o name | grep minikube | xargs -I {} kubectl config delete-context {} 2>/dev/null || true
    
    show_success "💥 Minikube COMPLETAMENTE DESTRUÍDO"
}

# Remover TODAS as imagens Docker
destroy_all_docker_images() {
    show_status "🔥 DESTRUINDO TODAS as imagens Docker relacionadas..."
    
    # Parar todos os containers
    docker stop $(docker ps -q) 2>/dev/null || true
    
    # Remover todos os containers
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    # Remover imagens específicas do projeto
    docker images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(desafiofilesharing|file-sharing)" | awk '{print $1}' | xargs -I {} docker rmi {} --force 2>/dev/null || true
    
    # Remover imagens órfãs
    docker image prune -af 2>/dev/null || true
    
    # Remover volumes órfãos
    docker volume prune -f 2>/dev/null || true
    
    # Remover networks órfãs
    docker network prune -f 2>/dev/null || true
    
    show_success "💥 Todas as imagens Docker DESTRUÍDAS"
}

# Destruir TODOS os certificados
destroy_certificates() {
    show_status "🔥 DESTRUINDO certificados..."
    
    # Remover diretório completo
    rm -rf certs/ 2>/dev/null || true
    
    # Remover certificados espalhados
    find . -name "*.crt" -delete 2>/dev/null || true
    find . -name "*.key" -delete 2>/dev/null || true
    find . -name "*.csr" -delete 2>/dev/null || true
    find . -name "*.srl" -delete 2>/dev/null || true
    find . -name "*.ext" -delete 2>/dev/null || true
    
    show_success "💥 Certificados DESTRUÍDOS"
}

# Limpar COMPLETAMENTE /etc/hosts
clean_hosts_file() {
    show_status "🔥 LIMPANDO /etc/hosts..."
    
    # Remover TODAS as entradas relacionadas
    sudo sed -i '' "/$DOMAIN/d" /etc/hosts 2>/dev/null || true
    sudo sed -i '' "/minikube/d" /etc/hosts 2>/dev/null || true
    sudo sed -i '' "/file-sharing/d" /etc/hosts 2>/dev/null || true
    sudo sed -i '' "/cloudwalk/d" /etc/hosts 2>/dev/null || true
    
    show_success "💥 /etc/hosts LIMPO"
}

# Destruir TODOS os arquivos temporários
destroy_temp_files() {
    show_status "🔥 DESTRUINDO TODOS os arquivos temporários..."
    
    # Node modules
    find . -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Arquivos de build
    find . -name "dist" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "build" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name ".next" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Logs
    find . -name "*.log" -delete 2>/dev/null || true
    rm -rf logs/ 2>/dev/null || true
    
    # Cache files
    find . -name ".cache" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name ".DS_Store" -delete 2>/dev/null || true
    find . -name "Thumbs.db" -delete 2>/dev/null || true
    
    # NPM/Yarn cache
    rm -rf ~/.npm/_cacache/ 2>/dev/null || true
    rm -rf ~/.yarn/cache/ 2>/dev/null || true
    
    # Docker context cache
    rm -rf ~/.docker/contexts/ 2>/dev/null || true
    
    # Arquivos backup do sed
    find . -name "*.bak" -delete 2>/dev/null || true
    
    show_success "💥 Arquivos temporários DESTRUÍDOS"
}

# Limpar configurações do kubectl
clean_kubectl_config() {
    show_status "🔥 LIMPANDO configurações kubectl..."
    
    # Remover contextos minikube
    kubectl config get-contexts -o name 2>/dev/null | grep -i minikube | xargs -I {} kubectl config delete-context {} 2>/dev/null || true
    
    # Remover clusters minikube
    kubectl config get-clusters 2>/dev/null | grep -i minikube | xargs -I {} kubectl config delete-cluster {} 2>/dev/null || true
    
    # Remover users minikube
    kubectl config get-users 2>/dev/null | grep -i minikube | xargs -I {} kubectl config delete-user {} 2>/dev/null || true
    
    show_success "💥 Configurações kubectl LIMPAS"
}

# Verificar se TUDO foi destruído
verify_total_destruction() {
    show_status "🔍 Verificando se TUDO foi destruído..."
    
    local remaining=0
    local warnings=()
    
    # Verificar Minikube
    if minikube status &>/dev/null; then
        warnings+=("Minikube ainda está rodando")
        remaining=$((remaining + 1))
    fi
    
    # Verificar imagens Docker
    local images=$(docker images --format "table {{.Repository}}" | grep -E "(desafiofilesharing|file-sharing)" 2>/dev/null | wc -l)
    if [ "$images" -gt 0 ]; then
        warnings+=("$images imagens Docker ainda existem")
        remaining=$((remaining + 1))
    fi
    
    # Verificar certificados
    if [ -d "certs" ] || find . -name "*.crt" 2>/dev/null | grep -q .; then
        warnings+=("Certificados ainda existem")
        remaining=$((remaining + 1))
    fi
    
    # Verificar hosts
    if grep -q "$DOMAIN\|minikube\|file-sharing" /etc/hosts 2>/dev/null; then
        warnings+=("Entradas no /etc/hosts ainda existem")
        remaining=$((remaining + 1))
    fi
    
    # Verificar node_modules
    if find . -name "node_modules" -type d 2>/dev/null | grep -q .; then
        warnings+=("node_modules ainda existem")
        remaining=$((remaining + 1))
    fi
    
    # Verificar port-forwards
    if pgrep -f "kubectl port-forward" &>/dev/null; then
        warnings+=("Processos port-forward ainda rodando")
        remaining=$((remaining + 1))
    fi
    
    if [ $remaining -eq 0 ]; then
        show_success "💥 DESTRUIÇÃO TOTAL CONFIRMADA!"
        echo -e "${GREEN}🎉 NADA RESTOU! Ambiente completamente limpo!${NC}"
    else
        show_warning "⚠️  $remaining itens ainda existem:"
        for warning in "${warnings[@]}"; do
            echo -e "${YELLOW}   - $warning${NC}"
        done
        echo -e "\n${BLUE}💡 Execute o cleanup novamente se necessário${NC}"
    fi
}

# Mostrar resumo da destruição
show_destruction_summary() {
    echo -e "\n${GREEN}💥 DESTRUIÇÃO TOTAL CONCLUÍDA!${NC}\n"
    
    echo -e "${RED}🔥 RESUMO DA DESTRUIÇÃO:${NC}"
    echo -e "${RED}========================${NC}"
    echo "💥 Minikube: COMPLETAMENTE DESTRUÍDO"
    echo "💥 Imagens Docker: TODAS REMOVIDAS"
    echo "💥 Certificados: DESTRUÍDOS"
    echo "💥 /etc/hosts: LIMPO"
    echo "💥 Arquivos temporários: DESTRUÍDOS"
    echo "💥 Node modules: DESTRUÍDOS"
    echo "💥 Port-forwards: MORTOS"
    echo "💥 Configurações kubectl: LIMPAS"
    
    echo -e "\n${GREEN}🔧 Para recriar do ZERO:${NC}"
    echo "   ./setup.sh"
    
    echo -e "\n${BLUE}📋 O que foi PERMANENTEMENTE perdido:${NC}"
    echo "   🗑️  Todos os dados de desenvolvimento"
    echo "   🗑️  Todas as configurações Kubernetes"
    echo "   🗑️  Todos os volumes e arquivos"
    echo "   🗑️  Todo cache e dependências"
    
    echo -e "\n${GREEN}✨ Ambiente 100% LIMPO e pronto para novo setup!${NC}"
}

# Função principal
main() {
    echo -e "${BLUE}Iniciando DESTRUIÇÃO TOTAL do ambiente...${NC}\n"
    
    confirm_total_cleanup
    
    kill_all_port_forwards
    destroy_minikube_completely
    destroy_all_docker_images
    destroy_certificates
    clean_hosts_file
    destroy_temp_files
    clean_kubectl_config
    verify_total_destruction
    show_destruction_summary
    
    echo -e "\n${RED}💥 DESTRUIÇÃO TOTAL CONCLUÍDA!${NC}"
    echo -e "${GREEN}🎯 Execute ./setup.sh para recriar tudo do zero!${NC}"
}

# Tratamento de erro
trap 'show_error "❌ Erro durante a destruição. Alguns recursos podem ainda existir."' ERR

# Executar função principal
main "$@"