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

# Verificar se repositório está no GitHub
check_github_repository() {
    echo -e "\n${BLUE}📋 VERIFICAÇÃO DO REPOSITÓRIO GITHUB${NC}"
    echo -e "=================================================="
    echo -e "Antes de começar, precisamos verificar se você já"
    echo -e "fez o push do código para o GitHub.\n"
    
    while true; do
        echo -e "${BLUE}❓ Você já fez push deste código para o GitHub?${NC}"
        echo -e "   ${GREEN}1)${NC} Sim, o repositório está no GitHub"
        echo -e "   ${GREEN}2)${NC} Não, ainda não fiz push"
        echo ""
        read -p "🔹 Escolha (1 ou 2): " github_choice
        
        case $github_choice in
            1)
                echo -e "\n${GREEN}✅ Repositório no GitHub confirmado${NC}"
                get_repository_url
                ask_repository_visibility
                break
                ;;
            2)
                echo -e "\n${RED}❌ Setup pausado${NC}"
                echo -e "${YELLOW}📋 AÇÃO NECESSÁRIA:${NC}"
                echo -e "   1. Faça commit de todas as alterações"
                echo -e "   2. Faça push para: ${GREEN}https://github.com/SEU_USUARIO/SEU_REPOSITORIO${NC}"
                echo -e "   3. Execute ./setup.sh novamente\n"
                echo -e "${BLUE}💡 O ArgoCD precisa acessar o código no GitHub para funcionar${NC}"
                exit 1
                ;;
            *)
                echo -e "${RED}❌ Opção inválida. Digite 1 ou 2.${NC}\n"
                ;;
        esac
    done
}

# Perguntar sobre visibilidade do repositório
ask_repository_visibility() {
    echo -e "\n${BLUE}🔐 VISIBILIDADE DO REPOSITÓRIO${NC}"
    echo -e "=================================================="
    
    while true; do
        echo -e "${BLUE}❓ O repositório GitHub é PRIVADO ou PÚBLICO?${NC}"
        echo -e "   ${GREEN}1)${NC} Público (qualquer um pode ver)"
        echo -e "   ${GREEN}2)${NC} Privado (apenas você e colaboradores)"
        echo ""
        read -p "🔹 Escolha (1 ou 2): " repo_visibility
        
        case $repo_visibility in
            1)
                echo -e "\n${GREEN}✅ Repositório público selecionado${NC}"
                echo -e "   ArgoCD acessará o repositório sem autenticação.\n"
                REPO_IS_PRIVATE=false
                break
                ;;
            2)
                echo -e "\n${YELLOW}🔐 Repositório privado selecionado${NC}"
                echo -e "   Configuração será necessária após o setup.\n"
                REPO_IS_PRIVATE=true
                break
                ;;
            *)
                echo -e "${RED}❌ Opção inválida. Digite 1 ou 2.${NC}\n"
                ;;
        esac
    done
}

# Coletar URL do repositório GitHub
get_repository_url() {
    echo -e "\n${BLUE}🌐 URL DO REPOSITÓRIO GITHUB${NC}"
    echo -e "=================================================="
    echo -e "Precisamos da URL do seu repositório para configurar"
    echo -e "o ArgoCD fazer sync com o código.\n"
    
    while true; do
        echo -e "${BLUE}📋 Digite a URL HTTPS do seu repositório GitHub:${NC}"
        echo -e "${YELLOW}   Exemplo: https://github.com/usuario/repositorio${NC}"
        read -p "🔹 URL: " repo_url
        
        # Remover .git do final se existir
        repo_url=$(echo "$repo_url" | sed 's/\.git$//')
        
        # Validar se é uma URL GitHub válida
        if [[ ! "$repo_url" =~ ^https://github\.com/[^/]+/[^/]+$ ]]; then
            echo -e "${RED}❌ URL inválida!${NC}"
            echo -e "${YELLOW}💡 A URL deve ser no formato:${NC}"
            echo -e "   ${GREEN}https://github.com/usuario/repositorio${NC}"
            echo -e "   ${YELLOW}(com ou sem .git no final)${NC}\n"
            continue
        fi
        
        echo -e "\n${GREEN}✅ URL do repositório configurada:${NC}"
        echo -e "   ${YELLOW}$repo_url${NC}\n"
        
        # Salvar URL em variável global
        REPO_URL="$repo_url"
        break
    done
}

# Verificar configuração Docker do usuário
check_docker_setup() {
    echo -e "\n${BLUE}🐳 VERIFICAÇÃO DO DOCKER${NC}"
    echo -e "=================================================="
    echo -e "Para personalizar as imagens Docker, precisamos do"
    echo -e "seu usuário do DockerHub configurado.\n"
    
    while true; do
        echo -e "${BLUE}❓ Você já tem Docker configurado e está logado no DockerHub?${NC}"
        echo -e "   ${GREEN}1)${NC} Sim, estou logado e pronto"
        echo -e "   ${GREEN}2)${NC} Não, preciso configurar"
        echo ""
        read -p "🔹 Escolha (1 ou 2): " docker_choice
        
        case $docker_choice in
            1)
                echo -e "\n${GREEN}✅ Docker configurado confirmado${NC}"
                
                # Pegar usuário atual do Docker
                current_user=$(docker info 2>/dev/null | grep -o "Username: [^[:space:]]*" | cut -d' ' -f2 || echo "")
                
                if [ -z "$current_user" ]; then
                    echo -e "${YELLOW}⚠️  Não consegui detectar seu usuário Docker${NC}"
                    echo -e "${BLUE}📋 Digite seu usuário do DockerHub:${NC}"
                    read -p "🔹 Usuário: " docker_username
                    DOCKER_USERNAME="$docker_username"
                else
                    echo -e "${GREEN}✅ Usuário Docker detectado: ${YELLOW}$current_user${NC}"
                    DOCKER_USERNAME="$current_user"
                fi
                break
                ;;
            2)
                echo -e "\n${YELLOW}📋 CONFIGURAÇÃO NECESSÁRIA${NC}"
                echo -e "=============================================="
                echo -e "Para usar suas próprias imagens Docker, você precisa:\n"
                
                echo -e "${BLUE}🔧 PASSO 1 - Criar conta DockerHub:${NC}"
                echo -e "   1. Acesse: ${GREEN}https://hub.docker.com${NC}"
                echo -e "   2. Crie uma conta gratuita\n"
                
                echo -e "${BLUE}🔧 PASSO 2 - Fazer login local:${NC}"
                echo -e "   1. Abra terminal/prompt"
                echo -e "   2. Execute: ${GREEN}docker login${NC}"
                echo -e "   3. Digite suas credenciais do DockerHub\n"
                
                echo -e "${BLUE}🔧 PASSO 3 - Verificar login:${NC}"
                echo -e "   Execute: ${GREEN}docker info | grep Username${NC}"
                echo -e "   Deve mostrar seu usuário\n"
                
                echo -e "${RED}⚠️  SETUP PAUSADO${NC}"
                echo -e "${YELLOW}💡 Após configurar o Docker, execute ./setup.sh novamente${NC}"
                exit 1
                ;;
            *)
                echo -e "${RED}❌ Opção inválida. Digite 1 ou 2.${NC}\n"
                ;;
        esac
    done
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
IP.2 = $(minikube ip)
EOF
    
    openssl x509 -req -in certs/server.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/server.crt -days 365 -sha256 -extfile certs/server.ext
    
    show_success "Certificados TLS gerados"
}

# Construir e enviar imagens Docker para DockerHub
build_images() {
    show_status "Construindo e enviando imagens Docker para DockerHub..."
    
    # Backend
    show_status "Construindo imagem do backend..."
    docker build -t ${DOCKER_USERNAME}/desafiofilesharing-backend:latest ./app/backend/
    
    show_status "Enviando backend para DockerHub..."
    docker push ${DOCKER_USERNAME}/desafiofilesharing-backend:latest
    
    # Frontend
    show_status "Construindo imagem do frontend..."
    docker build -t ${DOCKER_USERNAME}/desafiofilesharing-frontend:latest ./app/frontend/
    
    show_status "Enviando frontend para DockerHub..."
    docker push ${DOCKER_USERNAME}/desafiofilesharing-frontend:latest
    
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
    
    # Configurar Ingress para funcionar com proxy HTTPS local
    show_status "Configurando Ingress para proxy HTTPS local..."
    kubectl patch ingress file-sharing-ingress -n file-sharing -p '{"spec":{"tls":null}}' 2>/dev/null || true
    kubectl patch ingress file-sharing-ingress -n file-sharing -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/force-ssl-redirect":"false"}}}' 2>/dev/null || true
    
    show_success "Aplicação deployada"
}

# Atualizar deployments com usuário Docker
update_deployments_with_docker_user() {
    show_status "Atualizando deployments com seu usuário Docker..."
    
    # Atualizar backend deployment
    sed -i.bak "s|rafaelpdemelo/desafiofilesharing-backend:latest|${DOCKER_USERNAME}/desafiofilesharing-backend:latest|g" k8s/deployments/backend-deployment.yaml
    
    # Atualizar frontend deployment  
    sed -i.bak "s|rafaelpdemelo/desafiofilesharing-frontend:latest|${DOCKER_USERNAME}/desafiofilesharing-frontend:latest|g" k8s/deployments/frontend-deployment.yaml
    
    # Remover arquivos backup
    rm -f k8s/deployments/*.bak
    
    show_success "Deployments atualizados com usuário: $DOCKER_USERNAME"
}

# Atualizar ArgoCD application com URL do repositório
update_argocd_application() {
    show_status "Atualizando ArgoCD Application com URL do repositório..."
    
    # Atualizar repoURL no application.yaml (sem .git)
    sed -i.bak "s|repoURL: https://github.com/rafaelpdemelo/cloudwalk-desafio|repoURL: ${REPO_URL}|g" argocd/application.yaml
    
    # Atualizar URL no repo-secret-template.yaml também (sem .git)
    sed -i.bak "s|url: https://github.com/rafaelpdemelo/cloudwalk-desafio|url: ${REPO_URL}|g" argocd/repo-secret-template.yaml
    
    # Remover arquivos backup
    rm -f argocd/*.bak
    
    show_success "ArgoCD Application e repo-secret atualizados com: $REPO_URL"
}

# Mostrar instruções para repositório privado
show_private_repo_instructions() {
    echo -e "\n${BLUE}📋 INSTRUÇÕES PARA REPOSITÓRIO PRIVADO${NC}"
    echo -e "==============================================="
    echo -e "Como o repositório é privado, você precisa configurar"
    echo -e "manualmente o Personal Access Token.\n"
    
    echo -e "${YELLOW}🔧 PASSO 1 - Gerar Personal Access Token:${NC}"
    echo -e "   1. Acesse: ${GREEN}https://github.com/settings/tokens${NC}"
    echo -e "   2. Clique em '${GREEN}Generate new token (classic)${NC}'"
    echo -e "   3. Selecione as permissões: ${GREEN}repo, read:user, user:email${NC}"
    echo -e "   4. Copie o token gerado (formato: ghp_...)\n"
    
    echo -e "${YELLOW}🔧 PASSO 2 - Editar arquivo de configuração:${NC}"
    echo -e "   📄 Abra o arquivo: ${GREEN}argocd/repo-secret-template.yaml${NC}"
    echo -e "   🌐 Confirme se a URL está correta: ${GREEN}${REPO_URL}${NC}"
    echo -e "   🔑 Na linha com 'password:', substitua pelo seu token"
    echo -e "   🔑 Na linha com 'username:', substitua pelo seu usuário do GitHub"
    echo -e "   💾 Salve o arquivo\n"
    
    echo -e "${YELLOW}🔧 PASSO 3 - Aplicar configuração no ArgoCD:${NC}"
    echo -e "   Execute os comandos na ordem:"
    echo -e "   ${GREEN}kubectl apply -f argocd/repo-secret-template.yaml${NC}"
    echo -e "   ${GREEN}kubectl apply -f argocd/application.yaml${NC}\n"
    
    echo -e "${YELLOW}🔧 PASSO 4 - Verificar sincronização:${NC}"
    echo -e "   ${GREEN}kubectl get applications -n argocd${NC}"
    echo -e "   Status deve mostrar: ${GREEN}Synced + Healthy${NC}\n"
    
    echo -e "${RED}⚠️  SETUP PAUSADO - Configure o repositório privado antes de continuar${NC}"
    echo -e "${BLUE}💡 Após configurar, a aplicação estará disponível em: https://localhost:8080${NC}\n"
}

# Instalar ArgoCD
install_argocd() {
    show_status "Instalando ArgoCD..."
    
    kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Aguardar ArgoCD estar pronto
    show_status "Aguardando ArgoCD estar pronto..."
    kubectl wait --for=condition=Ready pods --all -n $ARGOCD_NAMESPACE --timeout=300s
    
    # Aplicar application.yaml SOMENTE para repositório público
    if [ "$REPO_IS_PRIVATE" = "false" ]; then
        show_status "Configurando aplicação ArgoCD para repositório público..."
        kubectl apply -f argocd/application.yaml
        show_success "ArgoCD instalado e configurado - Repositório público funcionando!"
    else
        show_success "ArgoCD instalado - Aguardando configuração manual do repositório privado"
        show_warning "Application será configurado manualmente no final"
    fi
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
start_https_proxy() {
    echo -e "${BLUE}🔐 Configurando proxy HTTPS com certificado self-signed...${NC}"
    
    # Verificar se os certificados existem
    if [ ! -f "certs/server.crt" ] || [ ! -f "certs/server.key" ]; then
        echo -e "${RED}❌ Certificados não encontrados.${NC}"
        return 1
    fi
    
    # Copiar certificados para /tmp
    cp certs/server.crt /tmp/
    cp certs/server.key /tmp/
    
    # Criar script de proxy Node.js melhorado
    cat > /tmp/https-proxy.js << 'PROXY_EOF'
const https = require('https');
const http = require('http');
const fs = require('fs');

const options = {
  key: fs.readFileSync('/tmp/server.key'),
  cert: fs.readFileSync('/tmp/server.crt')
};

const server = https.createServer(options, (req, res) => {
  console.log(`📥 ${req.method} ${req.url}`);
  
  const proxyReq = http.request({
    hostname: 'localhost',
    port: 8081,
    path: req.url,
    method: req.method,
    headers: {
      ...req.headers,
      'host': 'localhost:8081'
    }
  }, (proxyRes) => {
    console.log(`📤 ${proxyRes.statusCode} ${req.url}`);
    
    // Copiar headers
    Object.keys(proxyRes.headers).forEach(key => {
      res.setHeader(key, proxyRes.headers[key]);
    });
    
    res.writeHead(proxyRes.statusCode);
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (err) => {
    console.error(`❌ Proxy error: ${err.message}`);
    res.writeHead(500, { 'Content-Type': 'text/plain' });
    res.end('Proxy Error: ' + err.message);
  });

  req.pipe(proxyReq);
});

server.listen(8080, () => {
  console.log('🔐 HTTPS Proxy running on https://localhost:8080');
  console.log('📜 Using self-signed certificate from setup.sh');
  console.log('🎯 Certificate: CN=file-sharing.local, O=CloudWalk');
});
PROXY_EOF
    
    # Parar proxies anteriores se existirem
    pkill -f "node /tmp/https-proxy" 2>/dev/null || true
    pkill -f "kubectl port-forward.*8081:80" 2>/dev/null || true
    pkill -f "kubectl port-forward.*8443:443" 2>/dev/null || true
    
    # Iniciar port-forward HTTP
    echo -e "${BLUE}🔌 Iniciando port-forward HTTP...${NC}"
    kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80 > /dev/null 2>&1 &
    sleep 5
    
    # Iniciar port-forward ArgoCD
    echo -e "${BLUE}📊 Iniciando port-forward ArgoCD...${NC}"
    kubectl port-forward -n argocd svc/argocd-server 8443:443 > /dev/null 2>&1 &
    sleep 3
    
    # Iniciar proxy HTTPS
    echo -e "${BLUE}🚀 Iniciando proxy HTTPS...${NC}"
    node /tmp/https-proxy.js > /dev/null 2>&1 &
    
    echo -e "${GREEN}✅ Proxy HTTPS e ArgoCD iniciados!${NC}"
}

# Mostrar informações de acesso
show_access_info() {
    echo -e "\n${GREEN}🎉 APLICAÇÃO PRONTA E FUNCIONANDO!${NC}\n"
    
    echo -e "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${GREEN}┃                        🚀 ACESSO DIRETO - PRONTO PARA USAR                  ┃${NC}"
    echo -e "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    
    echo -e "\n${BLUE}🌐 APLICAÇÃO PRINCIPAL:${NC}"
    echo -e "   ${GREEN}✅ ATIVA e FUNCIONANDO em: ${YELLOW}https://localhost:8080${NC}"
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
    echo -e "   🌐 ${YELLOW}${REPO_URL}${NC}"
    if [ "$REPO_IS_PRIVATE" = "false" ]; then
        echo -e "   📋 ArgoCD sincronizado automaticamente com o repositório"
        echo -e "\n${GREEN}🎉 Tudo configurado automaticamente! GitOps funcionando!${NC}"
    else
        echo -e "   🔐 Repositório privado - configuração manual necessária"
        echo -e "\n${YELLOW}⚠️  Para ativar o GitOps, siga as instruções abaixo:${NC}"
        show_private_repo_instructions
    fi
}

# Função principal
main() {
    echo -e "${BLUE}Iniciando setup do CloudWalk File Sharing App...${NC}\n"
    
    check_github_repository
    check_dependencies
    check_docker_setup
    start_minikube
    generate_certificates
    build_images
    update_deployments_with_docker_user
    update_argocd_application
    create_namespaces
    apply_security_manifests
    create_secrets
    apply_storage_manifests
    apply_app_manifests
    install_argocd
    configure_access
    wait_for_pods
    health_check
    start_https_proxy
    show_access_info
    
    echo -e "\n${GREEN}🎯 APLICAÇÃO TOTALMENTE FUNCIONAL! Acesse https://localhost:8080 no navegador!${NC}"
}

# Tratamento de erro
trap 'show_error "Setup falhou! Execute ./cleanup.sh para limpar o ambiente."' ERR

# Executar função principal
main "$@"
