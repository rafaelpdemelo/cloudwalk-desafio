#!/bin/bash

# Script de Setup - CloudWalk Desafio
# Provisiona ambiente completo: minikube + ArgoCD + aplicação

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

# Função para verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    local deps=("kubectl" "helm" "minikube" "argocd")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "Dependências faltando: ${missing_deps[*]}"
        echo "Instale as dependências necessárias:"
        echo "  kubectl: https://kubernetes.io/docs/tasks/tools/"
        echo "  helm: https://helm.sh/docs/intro/install/"
        echo "  minikube: https://minikube.sigs.k8s.io/docs/start/"
        echo "  argocd: https://argo-cd.readthedocs.io/en/stable/getting_started/"
    fi
    
    success "Todas as dependências estão instaladas"
}

# Função para iniciar minikube
start_minikube() {
    log "Iniciando cluster Minikube..."
    
    if minikube status --profile="$MINIKUBE_PROFILE" | grep -q "Running"; then
        warning "Minikube já está rodando"
        return 0
    fi
    
    # Configurações básicas para minikube
    minikube start \
        --profile="$MINIKUBE_PROFILE" \
        --driver=docker \
        --cpus=2 \
        --memory=4096 \
        --disk-size=10g \
        --addons=ingress \
        --addons=storage-provisioner \
        --kubernetes-version=v1.28.0
    
    success "Minikube iniciado com sucesso"
}

# Função para configurar contexto kubectl
setup_kubectl_context() {
    log "Configurando contexto kubectl..."
    
    minikube kubectl --profile="$MINIKUBE_PROFILE" -- config use-context "$MINIKUBE_PROFILE"
    
    # Verificar se o contexto foi aplicado
    if ! kubectl config current-context | grep -q "$MINIKUBE_PROFILE"; then
        error "Falha ao configurar contexto kubectl"
    fi
    
    success "Contexto kubectl configurado"
}

# Função para instalar ArgoCD
install_argocd() {
    log "Instalando ArgoCD..."
    
    # Criar namespace se não existir
    kubectl create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Instalar ArgoCD
    kubectl apply -n "$ARGOCD_NAMESPACE" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Aguardar ArgoCD estar pronto
    log "Aguardando ArgoCD estar pronto..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n "$ARGOCD_NAMESPACE"
    
    success "ArgoCD instalado com sucesso"
}

# Função para configurar ArgoCD
configure_argocd() {
    log "Configurando ArgoCD..."
    
    # Obter senha inicial do ArgoCD
    ARGOCD_PASSWORD=$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    # Configurar port-forward para ArgoCD
    log "Configurando port-forward para ArgoCD (porta 8080)..."
    kubectl port-forward -n "$ARGOCD_NAMESPACE" svc/argocd-server 8080:443 &
    ARGOCD_PID=$!
    
    # Aguardar port-forward estar pronto
    sleep 5
    
    # Login no ArgoCD
    log "Fazendo login no ArgoCD..."
    argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure
    
    # Criar projeto específico para a aplicação
    log "Criando projeto ArgoCD específico..."
    kubectl apply -f "$PROJECT_ROOT/argocd/project.yaml"
    
    # Aplicar aplicação ArgoCD
    log "Aplicando aplicação ArgoCD..."
    kubectl apply -f "$PROJECT_ROOT/argocd/application.yaml"
    
    # Parar port-forward
    kill $ARGOCD_PID 2>/dev/null || true
    
    success "ArgoCD configurado com sucesso"
    log "Credenciais do ArgoCD:"
    log "  URL: https://localhost:8080"
    log "  Usuário: admin"
    log "  Senha: $ARGOCD_PASSWORD"
}

# Função para gerar certificados self-signed
generate_self_signed_certs() {
    log "Gerando certificados self-signed..."
    
    # Criar diretório para certificados
    mkdir -p "$PROJECT_ROOT/scripts/certs"
    
    # Gerar certificado CA
    openssl req -x509 -sha256 -days 365 -newkey rsa:2048 \
        -keyout "$PROJECT_ROOT/scripts/certs/ca.key" \
        -out "$PROJECT_ROOT/scripts/certs/ca.crt" \
        -subj "/C=BR/ST=SP/L=Sao Paulo/O=CloudWalk/OU=Desafio/CN=file-sharing-ca" \
        -nodes \
        -passout pass:
    
    # Gerar certificado do servidor
    openssl req -new -newkey rsa:2048 -keyout "$PROJECT_ROOT/scripts/certs/tls.key" \
        -out "$PROJECT_ROOT/scripts/certs/tls.csr" \
        -subj "/C=BR/ST=SP/L=Sao Paulo/O=CloudWalk/OU=Desafio/CN=file-sharing.local" \
        -nodes
    
    # Criar arquivo de configuração para extensões
    cat > "$PROJECT_ROOT/scripts/certs/tls.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = file-sharing.local
DNS.2 = *.file-sharing.local
IP.1 = 127.0.0.1
EOF
    
    # Assinar certificado
    openssl x509 -req -in "$PROJECT_ROOT/scripts/certs/tls.csr" \
        -CA "$PROJECT_ROOT/scripts/certs/ca.crt" \
        -CAkey "$PROJECT_ROOT/scripts/certs/ca.key" \
        -CAcreateserial \
        -out "$PROJECT_ROOT/scripts/certs/tls.crt" \
        -days 365 \
        -extfile "$PROJECT_ROOT/scripts/certs/tls.ext"
    
    # Criar secret no Kubernetes
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    kubectl create secret tls file-sharing-tls \
        --cert="$PROJECT_ROOT/scripts/certs/tls.crt" \
        --key="$PROJECT_ROOT/scripts/certs/tls.key" \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    success "Certificados self-signed gerados com sucesso"
}

# Função para configurar hosts local
setup_local_hosts() {
    log "Configurando hosts local..."
    
    # Obter IP do minikube
    MINIKUBE_IP=$(minikube ip --profile="$MINIKUBE_PROFILE")
    
    # Verificar se entrada já existe
    if ! grep -q "file-sharing.local" /etc/hosts; then
        echo "$MINIKUBE_IP file-sharing.local" | sudo tee -a /etc/hosts
        success "Hosts local configurado"
    else
        warning "Entrada file-sharing.local já existe no /etc/hosts"
    fi
}

# Função para verificar status final
check_final_status() {
    log "Verificando status final..."
    
    echo ""
    echo "=== STATUS DO CLUSTER ==="
    kubectl get nodes
    echo ""
    
    echo "=== STATUS DO ARGOCD ==="
    kubectl get pods -n "$ARGOCD_NAMESPACE"
    echo ""
    
    echo "=== STATUS DA APLICAÇÃO ==="
    kubectl get pods -n "$NAMESPACE" 2>/dev/null || echo "Aplicação ainda não foi deployada"
    echo ""
    
    success "Setup concluído com sucesso!"
    echo ""
    echo "📋 PRÓXIMOS PASSOS:"
    echo "1. Aguarde o ArgoCD sincronizar a aplicação (pode levar alguns minutos)"
    echo "2. Execute: make status"
    echo "3. Acesse: https://file-sharing.local"
    echo ""
    echo "🔐 CREDENCIAIS ARGOCD:"
    echo "  URL: https://localhost:8080"
    echo "  Usuário: admin"
    echo "  Senha: $(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
    echo ""
    echo "🌐 ACESSO À APLICAÇÃO:"
    echo "  Frontend: http://localhost:3000"
    echo "  Backend: http://localhost:3001"
    echo ""
    echo "[2025-08-28 18:13:34] Configurando port-forward automático..."
    
    # Configurar port-forward para ArgoCD
    kubectl port-forward -n argocd svc/argocd-server 8080:443 > /dev/null 2>&1 &
    echo $! > /tmp/argocd-port-forward.pid
    
    # Configurar port-forward para aplicação
    kubectl port-forward -n file-sharing svc/file-sharing-app-frontend 3000:80 > /dev/null 2>&1 &
    echo $! > /tmp/frontend-port-forward.pid
    
    kubectl port-forward -n file-sharing svc/file-sharing-app-backend 3001:3000 > /dev/null 2>&1 &
    echo $! > /tmp/backend-port-forward.pid
    
    echo "[SUCESSO] Port-forward configurado"
}

# Função principal
main() {
    echo "🚀 Iniciando setup do CloudWalk Desafio..."
    echo "=========================================="
    
    check_dependencies
    start_minikube
    setup_kubectl_context
    install_argocd
    configure_argocd
    generate_self_signed_certs
    setup_local_hosts
    check_final_status
}

# Executar função principal
main "$@"
