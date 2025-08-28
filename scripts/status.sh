#!/bin/bash

# Script de Status - CloudWalk Desafio
# Verifica status do cluster, ArgoCD e aplicações

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
    success "kubectl configurado"
}

# Função para verificar status do minikube
check_minikube() {
    log "Verificando status do Minikube..."
    
    if minikube status --profile="$MINIKUBE_PROFILE" | grep -q "Running"; then
        success "Minikube está rodando"
        
        # Mostrar informações do minikube
        echo "  Driver: $(minikube config get driver --profile="$MINIKUBE_PROFILE")"
        echo "  IP: $(minikube ip --profile="$MINIKUBE_PROFILE")"
        echo "  Kubernetes: $(minikube kubectl --profile="$MINIKUBE_PROFILE" -- version --client --short)"
    else
        error "Minikube não está rodando"
        echo "  Execute: make setup"
    fi
}

# Função para verificar status do cluster
check_cluster() {
    log "Verificando status do cluster..."
    
    echo ""
    echo "=== NODES ==="
    kubectl get nodes -o wide
    
    echo ""
    echo "=== NAMESPACES ==="
    kubectl get namespaces | grep -E "(file-sharing|argocd|ingress-nginx|kube-system)"
    
    echo ""
    echo "=== STORAGE CLASSES ==="
    kubectl get storageclass
}

# Função para verificar status do ArgoCD
check_argocd() {
    log "Verificando status do ArgoCD..."
    
    if kubectl get namespace "$ARGOCD_NAMESPACE" &>/dev/null; then
        echo ""
        echo "=== ARGOCD PODS ==="
        kubectl get pods -n "$ARGOCD_NAMESPACE" -o wide
        
        echo ""
        echo "=== ARGOCD SERVICES ==="
        kubectl get svc -n "$ARGOCD_NAMESPACE"
        
        echo ""
        echo "=== ARGOCD APPLICATIONS ==="
        kubectl get application -n "$ARGOCD_NAMESPACE" -o wide
        
        echo ""
        echo "=== ARGOCD PROJECTS ==="
        kubectl get appproject -n "$ARGOCD_NAMESPACE"
        
        # Verificar se ArgoCD está saudável
        if kubectl get pods -n "$ARGOCD_NAMESPACE" | grep -q "Running"; then
            success "ArgoCD está funcionando"
        else
            error "ArgoCD não está funcionando corretamente"
        fi
    else
        error "Namespace do ArgoCD não encontrado"
        echo "  Execute: make setup"
    fi
}

# Função para verificar status da aplicação
check_application() {
    log "Verificando status da aplicação..."
    
    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
        echo ""
        echo "=== APLICAÇÃO PODS ==="
        kubectl get pods -n "$NAMESPACE" -o wide
        
        echo ""
        echo "=== APLICAÇÃO SERVICES ==="
        kubectl get svc -n "$NAMESPACE"
        
        echo ""
        echo "=== APLICAÇÃO INGRESS ==="
        kubectl get ingress -n "$NAMESPACE"
        
        echo ""
        echo "=== APLICAÇÃO SECRETS ==="
        kubectl get secrets -n "$NAMESPACE"
        
        echo ""
        echo "=== APLICAÇÃO CONFIGMAPS ==="
        kubectl get configmaps -n "$NAMESPACE"
        
        # Verificar se todos os pods estão rodando
        local total_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers | wc -l)
        local running_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers | grep -c "Running" || echo "0")
        
        if [ "$total_pods" -gt 0 ] && [ "$running_pods" -eq "$total_pods" ]; then
            success "Aplicação está funcionando ($running_pods/$total_pods pods rodando)"
        else
            warning "Aplicação não está totalmente funcional ($running_pods/$total_pods pods rodando)"
        fi
    else
        error "Namespace da aplicação não encontrado"
        echo "  Execute: make setup"
    fi
}

# Função para verificar recursos do sistema
check_resources() {
    log "Verificando recursos do sistema..."
    
    echo ""
    echo "=== RESOURCE USAGE ==="
    kubectl top nodes 2>/dev/null || echo "  Metrics server não disponível"
    
    echo ""
    echo "=== POD RESOURCES ==="
    kubectl top pods -n "$NAMESPACE" 2>/dev/null || echo "  Metrics server não disponível"
    
    echo ""
    echo "=== HPA STATUS ==="
    kubectl get hpa -n "$NAMESPACE" 2>/dev/null || echo "  HPA não configurado"
}

# Função para verificar conectividade
check_connectivity() {
    log "Verificando conectividade..."
    
    # Verificar se o domínio está resolvendo
    if nslookup file-sharing.local &>/dev/null; then
        success "Domínio file-sharing.local está resolvendo"
    else
        warning "Domínio file-sharing.local não está resolvendo"
        echo "  Verifique o arquivo /etc/hosts"
    fi
    
    # Verificar se o ingress está funcionando
    if kubectl get ingress -n "$NAMESPACE" &>/dev/null; then
        local ingress_ip=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [ -n "$ingress_ip" ]; then
            success "Ingress está configurado (IP: $ingress_ip)"
        else
            warning "Ingress não tem IP atribuído"
        fi
    fi
}

# Função para verificar certificados
check_certificates() {
    log "Verificando certificados..."
    
    if [ -f "scripts/certs/tls.crt" ]; then
        local expiry_date=$(openssl x509 -in scripts/certs/tls.crt -noout -enddate | cut -d= -f2)
        success "Certificado TLS encontrado (expira em: $expiry_date)"
    else
        warning "Certificado TLS não encontrado"
        echo "  Execute: make generate-certs"
    fi
    
    # Verificar secret no Kubernetes
    if kubectl get secret file-sharing-tls -n "$NAMESPACE" &>/dev/null; then
        success "Secret TLS configurado no Kubernetes"
    else
        warning "Secret TLS não encontrado no Kubernetes"
    fi
}

# Função para verificar logs de erro
check_error_logs() {
    log "Verificando logs de erro..."
    
    echo ""
    echo "=== LOGS DE ERRO (últimas 10 linhas) ==="
    
    # Logs do frontend
    echo "Frontend:"
    kubectl logs -n "$NAMESPACE" deployment/file-sharing-app-frontend --tail=10 2>/dev/null | grep -i error || echo "  Nenhum erro encontrado"
    
    echo ""
    echo "Backend:"
    kubectl logs -n "$NAMESPACE" deployment/file-sharing-app-backend --tail=10 2>/dev/null | grep -i error || echo "  Nenhum erro encontrado"
    
    echo ""
    echo "Ingress:"
    kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=10 2>/dev/null | grep -i error || echo "  Nenhum erro encontrado"
}

# Função para mostrar resumo
show_summary() {
    log "Resumo do status..."
    
    echo ""
    echo "=== RESUMO ==="
    
    # Status do minikube
    if minikube status --profile="$MINIKUBE_PROFILE" | grep -q "Running"; then
        echo "✅ Minikube: Rodando"
    else
        echo "❌ Minikube: Parado"
    fi
    
    # Status do ArgoCD
    if kubectl get pods -n "$ARGOCD_NAMESPACE" | grep -q "Running"; then
        echo "✅ ArgoCD: Funcionando"
    else
        echo "❌ ArgoCD: Não funcionando"
    fi
    
    # Status da aplicação
    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
        local total_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers | wc -l)
        local running_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers | grep -c "Running" || echo "0")
        if [ "$total_pods" -gt 0 ] && [ "$running_pods" -eq "$total_pods" ]; then
            echo "✅ Aplicação: Funcionando ($running_pods/$total_pods pods)"
        else
            echo "⚠️  Aplicação: Parcialmente funcional ($running_pods/$total_pods pods)"
        fi
    else
        echo "❌ Aplicação: Não encontrada"
    fi
    
    # Status do certificado
    if [ -f "scripts/certs/tls.crt" ]; then
        echo "✅ Certificado: Configurado"
    else
        echo "❌ Certificado: Não encontrado"
    fi
    
    echo ""
    echo "=== PRÓXIMOS PASSOS ==="
    echo "1. Para acessar a aplicação: make port-forward"
    echo "2. Para ver logs detalhados: make logs"
    echo "3. Para acessar ArgoCD: kubectl port-forward -n argocd svc/argocd-server 8080:443"
    echo "4. Para troubleshooting: make troubleshoot"
}

# Função principal
main() {
    echo "📊 Verificando status do CloudWalk Desafio..."
    echo "============================================="
    
    check_kubectl
    check_minikube
    check_cluster
    check_argocd
    check_application
    check_resources
    check_connectivity
    check_certificates
    check_error_logs
    show_summary
}

# Executar função principal
main "$@"
