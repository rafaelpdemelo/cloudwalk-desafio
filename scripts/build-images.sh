#!/bin/bash

# Script para build e push das imagens Docker
# CloudWalk Desafio - File Sharing App

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
DOCKER_USERNAME="rafaelpdemelo"
FRONTEND_IMAGE="desafiofilesharing-frontend"
BACKEND_IMAGE="desafiofilesharing-backend"
TAG="latest"

echo -e "${BLUE}🐳 Build e Push das Imagens Docker${NC}"
echo "=========================================="

# Função para build e push
build_and_push() {
    local component=$1
    local image_name=$2
    local dockerfile_path=$3
    
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] Buildando imagem $image_name...${NC}"
    
    # Build da imagem
    docker build -t "$DOCKER_USERNAME/$image_name:$TAG" "$dockerfile_path"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCESSO] Build da imagem $image_name concluído${NC}"
    else
        echo -e "${RED}[ERRO] Falha no build da imagem $image_name${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] Fazendo push da imagem $image_name...${NC}"
    
    # Push da imagem
    docker push "$DOCKER_USERNAME/$image_name:$TAG"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCESSO] Push da imagem $image_name concluído${NC}"
    else
        echo -e "${RED}[ERRO] Falha no push da imagem $image_name${NC}"
        exit 1
    fi
}

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}[ERRO] Docker não está rodando${NC}"
    exit 1
fi

# Build e push do Frontend
build_and_push "Frontend" "$FRONTEND_IMAGE" "app/frontend"

# Build e push do Backend
build_and_push "Backend" "$BACKEND_IMAGE" "app/backend"

echo ""
echo -e "${GREEN}🎉 Build e push de todas as imagens concluído com sucesso!${NC}"
echo ""
echo -e "${BLUE}📋 Imagens disponíveis:${NC}"
echo "  Frontend: $DOCKER_USERNAME/$FRONTEND_IMAGE:$TAG"
echo "  Backend: $DOCKER_USERNAME/$BACKEND_IMAGE:$TAG"
echo ""
echo -e "${YELLOW}💡 Para aplicar as novas imagens:${NC}"
echo "  1. Execute: make cleanup"
echo "  2. Execute: make setup"
echo "  3. Ou force o restart dos pods: kubectl rollout restart deployment -n file-sharing"
