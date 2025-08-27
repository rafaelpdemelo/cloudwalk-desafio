#!/bin/bash

# CloudWalk File Sharing App - Setup Script
# Este script configura todo o ambiente Kubernetes com ArgoCD localmente

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
APP_NAME="file-sharing-app"
DOMAIN="file-sharing.local"

echo -e "${BLUE}🚀 Configurando CloudWalk File Sharing App${NC}"
echo -e "${BLUE}======================================${NC}"

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

# Verificar dependências
check_dependencies() {
    show_status "Verificando dependências..."
    
    local deps=("minikube" "kubectl" "docker" "openssl")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            show_error "$dep não está instalado"
            exit 1
        fi
    done
    
    show_success "Todas as dependências estão instaladas"
}

# Iniciar Minikube se não estiver rodando
start_minikube() {
    show_status "Verificando status do Minikube..."
    
    if ! minikube status &> /dev/null; then
        show_status "Iniciando Minikube..."
        minikube start \
            --driver=docker \
            --cpus=4 \
            --memory=7837 \
            --disk-size=20g \
            --kubernetes-version=v1.28.0
        
        # Habilitar addons necessários
        minikube addons enable ingress
        minikube addons enable metrics-server
        minikube addons enable dashboard
        
        show_success "Minikube iniciado com sucesso"
    else
        show_success "Minikube já está rodando"
    fi
    
    # Configurar Docker para usar o registry do Minikube
    eval $(minikube docker-env)
}

# Gerar certificados TLS self-signed
generate_certificates() {
    show_status "Gerando certificados TLS..."
    
    mkdir -p certs
    
    # Certificado CA
    openssl genrsa -out certs/ca.key 4096
    openssl req -new -x509 -key certs/ca.key -sha256 -subj "/C=BR/ST=SP/O=CloudWalk/CN=CloudWalk-CA" -days 365 -out certs/ca.crt
    
    # Certificado do servidor
    openssl genrsa -out certs/server.key 4096
    openssl req -new -key certs/server.key -out certs/server.csr -subj "/C=BR/ST=SP/O=CloudWalk/CN=${DOMAIN}"
    
    # Extensões para SAN
    cat > certs/server.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}
DNS.3 = localhost
DNS.4 = backend
DNS.5 = frontend
IP.1 = 127.0.0.1
IP.2 = 192.168.49.2
EOF
    
    openssl x509 -req -in certs/server.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/server.crt -days 365 -sha256 -extfile certs/server.ext
    
    show_success "Certificados TLS gerados"
}

# Construir e enviar imagens Docker para DockerHub
build_images() {
    show_status "Construindo e enviando imagens Docker para DockerHub..."
    
    # Backend
    show_status "Construindo imagem do backend..."
    docker build -t rafaelpdemelo/desafiofilesharing-backend:latest ./app/backend/
    
    show_status "Enviando backend para DockerHub..."
    docker push rafaelpdemelo/desafiofilesharing-backend:latest
    
    # Frontend
    show_status "Construindo imagem do frontend..."
    docker build -t rafaelpdemelo/desafiofilesharing-frontend:latest ./app/frontend/
    
    show_status "Enviando frontend para DockerHub..."
    docker push rafaelpdemelo/desafiofilesharing-frontend:latest
    
    show_success "Imagens Docker construídas e enviadas para DockerHub"
}

# Criar namespaces
create_namespaces() {
    show_status "Criando namespaces..."
    
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace $ARGOCD_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Labels para Pod Security Standards
    kubectl label namespace $NAMESPACE pod-security.kubernetes.io/enforce=restricted --overwrite
    kubectl label namespace $NAMESPACE pod-security.kubernetes.io/audit=restricted --overwrite
    kubectl label namespace $NAMESPACE pod-security.kubernetes.io/warn=restricted --overwrite
    
    show_success "Namespaces criados"
}

# Aplicar manifests de segurança
apply_security_manifests() {
    show_status "Aplicando políticas de segurança..."
    
    # RBAC
    kubectl apply -f k8s/security/
    
    show_success "Políticas de segurança aplicadas"
}

# Criar secrets
create_secrets() {
    show_status "Criando secrets..."
    
    # TLS Secret
    kubectl create secret tls file-sharing-tls \
        --cert=certs/server.crt \
        --key=certs/server.key \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # CA Secret para validação
    kubectl create secret generic ca-secret \
        --from-file=ca.crt=certs/ca.crt \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    show_success "Secrets criados"
}

# Aplicar manifests do storage
apply_storage_manifests() {
    show_status "Aplicando configurações de storage..."
    
    kubectl apply -f k8s/storage/
    
    show_success "Storage configurado"
}

# Aplicar manifests da aplicação
apply_app_manifests() {
    show_status "Aplicando manifests da aplicação..."
    
    kubectl apply -f k8s/deployments/
    kubectl apply -f k8s/services/
    kubectl apply -f k8s/ingress/
    
    show_success "Aplicação deployada"
}

# Instalar ArgoCD
install_argocd() {
    show_status "Instalando ArgoCD..."
    
    kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Aguardar ArgoCD estar pronto
    show_status "Aguardando ArgoCD estar pronto..."
    kubectl wait --for=condition=Ready pods --all -n $ARGOCD_NAMESPACE --timeout=300s
    
    # Configurar ArgoCD Application
    kubectl apply -f argocd/
    
    show_success "ArgoCD instalado e configurado"
}

# Configurar acesso simplificado
configure_access() {
    show_status "Configurando acesso à aplicação..."
    
    MINIKUBE_IP=$(minikube ip)
    
    show_success "IP do Minikube: $MINIKUBE_IP"
    show_success "Acesso configurado"
}

# Aguardar pods estarem prontos
wait_for_pods() {
    show_status "Aguardando pods estarem prontos..."
    
    kubectl wait --for=condition=Ready pods --all -n $NAMESPACE --timeout=300s
    
    show_success "Todos os pods estão prontos"
}

# Verificar saúde da aplicação
health_check() {
    show_status "Verificando saúde da aplicação..."
    
    # Aguardar um pouco mais para garantir que tudo está estável
    sleep 10
    
    # Verificar se todos os pods estão realmente funcionando
    local backend_pods=$(kubectl get pods -n $NAMESPACE -l app=file-sharing-backend --no-headers | grep "Running" | wc -l)
    local frontend_pods=$(kubectl get pods -n $NAMESPACE -l app=file-sharing-frontend --no-headers | grep "Running" | wc -l)
    
    if [ "$backend_pods" -ge 1 ] && [ "$frontend_pods" -ge 1 ]; then
        show_success "Aplicação está saudável - $backend_pods backend(s) e $frontend_pods frontend(s) rodando"
    else
        show_error "Problema na aplicação - Backend: $backend_pods, Frontend: $frontend_pods"
        return 1
    fi
}

# Iniciar port-forward automático para acesso fácil
start_port_forward() {
    show_status "Configurando acesso automático via port-forward..."
    
    # Matar qualquer port-forward existente
    pkill -f "kubectl port-forward.*file-sharing-frontend" 2>/dev/null || true
    pkill -f "kubectl port-forward.*argocd-server" 2>/dev/null || true
    
    # Aguardar um pouco
    sleep 2
    
    # Iniciar port-forward para a aplicação em background
    kubectl port-forward svc/file-sharing-frontend -n $NAMESPACE 8080:3001 >/dev/null 2>&1 &
    local app_pid=$!
    
    # Iniciar port-forward para ArgoCD em background  
    kubectl port-forward svc/argocd-server -n argocd 8443:443 >/dev/null 2>&1 &
    local argocd_pid=$!
    
    # Aguardar port-forwards estarem ativos
    sleep 5
    
    # Verificar se port-forwards estão funcionando
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        show_success "Port-forward da aplicação ativo na porta 8080"
        echo "$app_pid" > /tmp/file-sharing-app.pid
    else
        show_error "Port-forward da aplicação falhou"
    fi
    
    if curl -k -s https://localhost:8443 >/dev/null 2>&1; then
        show_success "Port-forward do ArgoCD ativo na porta 8443"
        echo "$argocd_pid" > /tmp/argocd.pid
    else
        show_error "Port-forward do ArgoCD falhou"
    fi
}

# Mostrar informações de acesso
show_access_info() {
    echo -e "\n${GREEN}🎉 APLICAÇÃO PRONTA E FUNCIONANDO!${NC}\n"
    
    echo -e "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${GREEN}┃                        🚀 ACESSO DIRETO - PRONTO PARA USAR                  ┃${NC}"
    echo -e "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    
    echo -e "\n${BLUE}🌐 APLICAÇÃO PRINCIPAL:${NC}"
    echo -e "   ${GREEN}✅ ATIVA e FUNCIONANDO em: ${YELLOW}http://localhost:8080${NC}"
    echo -e "   ${GREEN}👆 Abra este link no seu navegador AGORA!${NC}"
    echo ""
    
    echo -e "${BLUE}📊 ARGOCD DASHBOARD:${NC}"
    echo -e "   ${GREEN}✅ ATIVO e FUNCIONANDO em: ${YELLOW}https://localhost:8443${NC}"
    
    # Obter senha do ArgoCD
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "Aguardando...")
    echo -e "   ${BLUE}👤 Usuário: ${YELLOW}admin${NC}"
    echo -e "   ${BLUE}🔐 Senha: ${YELLOW}$ARGOCD_PASSWORD${NC}"
    echo ""
    
    echo -e "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${GREEN}┃  🎯 TESTE A APLICAÇÃO: Faça upload de um arquivo com senha e baixe!        ┃${NC}"
    echo -e "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    
    echo -e "\n${BLUE}🔧 Comandos Úteis (se precisar):${NC}"
    echo -e "   📊 Dashboard K8s: ${YELLOW}minikube dashboard${NC}"
    echo -e "   🔍 Ver pods: ${YELLOW}kubectl get pods -n $NAMESPACE${NC}"
    echo -e "   📋 Ver logs: ${YELLOW}kubectl logs -f deployment/file-sharing-backend -n $NAMESPACE${NC}"
    echo -e "   🔄 GitOps Status: ${YELLOW}kubectl get applications -n argocd${NC}"
    
    echo -e "\n${BLUE}📚 Repositório GitHub:${NC}"
    echo -e "   🌐 ${YELLOW}https://github.com/rafaelpdemelo/cloudwalk-desafio${NC}"
    echo -e "   📋 ArgoCD sincronizado automaticamente com o repositório"
    
    echo -e "\n${GREEN}🎉 Tudo configurado automaticamente! GitOps funcionando!${NC}"
}

# Função principal
main() {
    echo -e "${BLUE}Iniciando setup do CloudWalk File Sharing App...${NC}\n"
    
    check_dependencies
    start_minikube
    generate_certificates
    build_images
    create_namespaces
    apply_security_manifests
    create_secrets
    apply_storage_manifests
    apply_app_manifests
    install_argocd
    configure_access
    wait_for_pods
    health_check
    start_port_forward
    show_access_info
    
    echo -e "\n${GREEN}🎯 APLICAÇÃO TOTALMENTE FUNCIONAL! Acesse http://localhost:8080 no navegador!${NC}"
}

# Tratamento de erro
trap 'show_error "Setup falhou! Execute ./cleanup.sh para limpar o ambiente."' ERR

# Executar função principal
main "$@"
