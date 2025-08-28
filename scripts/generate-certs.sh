#!/bin/bash

# Script de Geração de Certificados - CloudWalk Desafio
# Gera certificados self-signed para TLS

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CERTS_DIR="$PROJECT_ROOT/scripts/certs"

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

# Função para verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    if ! command -v openssl &> /dev/null; then
        error "OpenSSL não está instalado"
        echo "Instale o OpenSSL:"
        echo "  macOS: brew install openssl"
        echo "  Ubuntu/Debian: sudo apt-get install openssl"
        echo "  CentOS/RHEL: sudo yum install openssl"
        exit 1
    fi
    
    success "OpenSSL está instalado"
}

# Função para criar diretório de certificados
create_certs_directory() {
    log "Criando diretório de certificados..."
    
    if [ -d "$CERTS_DIR" ]; then
        warning "Diretório de certificados já existe"
        read -p "Deseja sobrescrever os certificados existentes? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Operação cancelada"
            exit 0
        fi
        
        # Fazer backup dos certificados existentes
        if [ -f "$CERTS_DIR/tls.crt" ] || [ -f "$CERTS_DIR/tls.key" ]; then
            local backup_dir="$CERTS_DIR/backup-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$backup_dir"
            cp -r "$CERTS_DIR"/* "$backup_dir/" 2>/dev/null || true
            success "Backup criado em: $backup_dir"
        fi
        
        # Limpar diretório
        rm -rf "$CERTS_DIR"/*
    else
        mkdir -p "$CERTS_DIR"
    fi
    
    success "Diretório de certificados criado: $CERTS_DIR"
}

# Função para gerar certificado CA
generate_ca_certificate() {
    log "Gerando certificado CA..."
    
    # Gerar chave privada da CA
    openssl genrsa -out "$CERTS_DIR/ca.key" 4096
    
    # Gerar certificado da CA
    openssl req -x509 -new -nodes \
        -key "$CERTS_DIR/ca.key" \
        -sha256 -days 3650 \
        -out "$CERTS_DIR/ca.crt" \
        -subj "/C=BR/ST=SP/L=Sao Paulo/O=CloudWalk/OU=Desafio/CN=file-sharing-ca"
    
    success "Certificado CA gerado"
}

# Função para gerar certificado do servidor
generate_server_certificate() {
    log "Gerando certificado do servidor..."
    
    # Gerar chave privada do servidor
    openssl genrsa -out "$CERTS_DIR/tls.key" 2048
    
    # Gerar CSR (Certificate Signing Request)
    openssl req -new \
        -key "$CERTS_DIR/tls.key" \
        -out "$CERTS_DIR/tls.csr" \
        -subj "/C=BR/ST=SP/L=Sao Paulo/O=CloudWalk/OU=Desafio/CN=file-sharing.local"
    
    # Criar arquivo de configuração para extensões
    cat > "$CERTS_DIR/tls.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = file-sharing.local
DNS.2 = *.file-sharing.local
DNS.3 = localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF
    
    # Assinar certificado com a CA
    openssl x509 -req \
        -in "$CERTS_DIR/tls.csr" \
        -CA "$CERTS_DIR/ca.crt" \
        -CAkey "$CERTS_DIR/ca.key" \
        -CAcreateserial \
        -out "$CERTS_DIR/tls.crt" \
        -days 365 \
        -sha256 \
        -extfile "$CERTS_DIR/tls.ext"
    
    success "Certificado do servidor gerado"
}

# Função para gerar certificado cliente (opcional)
generate_client_certificate() {
    log "Gerando certificado cliente..."
    
    # Gerar chave privada do cliente
    openssl genrsa -out "$CERTS_DIR/client.key" 2048
    
    # Gerar CSR do cliente
    openssl req -new \
        -key "$CERTS_DIR/client.key" \
        -out "$CERTS_DIR/client.csr" \
        -subj "/C=BR/ST=SP/L=Sao Paulo/O=CloudWalk/OU=Desafio/CN=file-sharing-client"
    
    # Criar arquivo de configuração para extensões do cliente
    cat > "$CERTS_DIR/client.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = file-sharing-client
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF
    
    # Assinar certificado do cliente
    openssl x509 -req \
        -in "$CERTS_DIR/client.csr" \
        -CA "$CERTS_DIR/ca.crt" \
        -CAkey "$CERTS_DIR/ca.key" \
        -CAserial "$CERTS_DIR/ca.srl" \
        -out "$CERTS_DIR/client.crt" \
        -days 365 \
        -sha256 \
        -extfile "$CERTS_DIR/client.ext"
    
    success "Certificado cliente gerado"
}

# Função para configurar permissões
set_permissions() {
    log "Configurando permissões..."
    
    # Definir permissões seguras
    chmod 600 "$CERTS_DIR"/*.key
    chmod 644 "$CERTS_DIR"/*.crt
    chmod 644 "$CERTS_DIR"/*.csr
    chmod 644 "$CERTS_DIR"/*.ext
    chmod 644 "$CERTS_DIR"/*.srl
    
    success "Permissões configuradas"
}

# Função para criar secret no Kubernetes
create_kubernetes_secret() {
    log "Criando secret no Kubernetes..."
    
    # Verificar se kubectl está configurado
    if ! kubectl cluster-info &>/dev/null; then
        warning "kubectl não está configurado, pulando criação do secret"
        return 0
    fi
    
    # Criar namespace se não existir
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Criar secret TLS
    kubectl create secret tls file-sharing-tls \
        --cert="$CERTS_DIR/tls.crt" \
        --key="$CERTS_DIR/tls.key" \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    success "Secret TLS criado no Kubernetes"
}

# Função para verificar certificados
verify_certificates() {
    log "Verificando certificados..."
    
    echo ""
    echo "=== INFORMAÇÕES DOS CERTIFICADOS ==="
    
    # Verificar certificado CA
    echo "CA Certificate:"
    openssl x509 -in "$CERTS_DIR/ca.crt" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:)"
    
    echo ""
    echo "Server Certificate:"
    openssl x509 -in "$CERTS_DIR/tls.crt" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:|DNS:|IP Address:)"
    
    echo ""
    echo "=== VALIDAÇÃO ==="
    
    # Verificar se o certificado do servidor é válido
    if openssl verify -CAfile "$CERTS_DIR/ca.crt" "$CERTS_DIR/tls.crt" &>/dev/null; then
        success "Certificado do servidor é válido"
    else
        error "Certificado do servidor é inválido"
    fi
    
    # Verificar se o certificado cliente é válido (se existir)
    if [ -f "$CERTS_DIR/client.crt" ]; then
        if openssl verify -CAfile "$CERTS_DIR/ca.crt" "$CERTS_DIR/client.crt" &>/dev/null; then
            success "Certificado cliente é válido"
        else
            error "Certificado cliente é inválido"
        fi
    fi
}

# Função para mostrar informações de uso
show_usage_info() {
    log "Informações de uso..."
    
    echo ""
    echo "=== ARQUIVOS GERADOS ==="
    ls -la "$CERTS_DIR"/
    
    echo ""
    echo "=== COMO USAR ==="
    echo "1. Para desenvolvimento local:"
    echo "   - Os certificados já estão configurados no Kubernetes"
    echo "   - Acesse: https://file-sharing.local"
    echo ""
    echo "2. Para importar CA no navegador:"
    echo "   - Importe: $CERTS_DIR/ca.crt"
    echo "   - Marque como confiável para certificados de servidor"
    echo ""
    echo "3. Para usar com curl:"
    echo "   curl --cacert $CERTS_DIR/ca.crt https://file-sharing.local"
    echo ""
    echo "4. Para regenerar certificados:"
    echo "   make generate-certs"
    
    echo ""
    echo "⚠️  IMPORTANTE:"
    echo "   - Estes são certificados self-signed para desenvolvimento"
    echo "   - NÃO use em produção"
    echo "   - Validade: 365 dias"
}

# Função principal
main() {
    echo "🔐 Gerando certificados self-signed para CloudWalk Desafio..."
    echo "============================================================"
    
    check_dependencies
    create_certs_directory
    generate_ca_certificate
    generate_server_certificate
    generate_client_certificate
    set_permissions
    create_kubernetes_secret
    verify_certificates
    show_usage_info
    
    success "Certificados gerados com sucesso!"
    echo ""
    echo "💡 Para aplicar no cluster: make setup"
    echo "💡 Para verificar status: make status"
}

# Executar função principal
main "$@"
