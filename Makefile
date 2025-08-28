# Makefile para CloudWalk Desafio - File Sharing App
# Comandos para gerenciar a infraestrutura Kubernetes + GitOps

.PHONY: help setup cleanup deploy undeploy status logs port-forward test-ddos

# Variáveis
PROJECT_NAME := file-sharing-app
NAMESPACE := file-sharing
ARGOCD_NAMESPACE := argocd
MINIKUBE_PROFILE := cloudwalk-desafio

# Cores para output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

help: ## Mostra esta ajuda
	@echo "$(BLUE)CloudWalk Desafio - File Sharing App$(NC)"
	@echo "$(YELLOW)Comandos disponíveis:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

setup: ## Provisiona o ambiente completo (minikube + ArgoCD + app)
	@echo "$(BLUE)🚀 Iniciando setup completo do ambiente...$(NC)"
	@chmod +x scripts/setup.sh
	@./scripts/setup.sh

cleanup: ## Remove completamente o ambiente
	@echo "$(RED)🧹 Limpando ambiente completo...$(NC)"
	@chmod +x scripts/cleanup.sh
	@./scripts/cleanup.sh

deploy: ## Deploy da aplicação via ArgoCD
	@echo "$(BLUE)📦 Fazendo deploy da aplicação...$(NC)"
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh

undeploy: ## Remove a aplicação do cluster
	@echo "$(YELLOW)🗑️  Removendo aplicação...$(NC)"
	@chmod +x scripts/undeploy.sh
	@./scripts/undeploy.sh

status: ## Verifica status do cluster e aplicações
	@echo "$(BLUE)📊 Verificando status...$(NC)"
	@chmod +x scripts/status.sh
	@./scripts/status.sh

logs: ## Mostra logs das aplicações
	@echo "$(BLUE)📋 Mostrando logs...$(NC)"
	@chmod +x scripts/logs.sh
	@./scripts/logs.sh

port-forward: ## Configura port-forward para acesso local
	@echo "$(BLUE)🔗 Configurando port-forward...$(NC)"
	@chmod +x scripts/port-forward.sh
	@./scripts/port-forward.sh

stop-port-forwards: ## Para todos os port-forwards
	@echo "$(YELLOW)🛑 Parando port-forwards...$(NC)"
	@chmod +x scripts/stop-port-forwards.sh
	@./scripts/stop-port-forwards.sh

test-ddos: ## Executa teste de proteção DDOS
	@echo "$(RED)🛡️  Testando proteção DDOS...$(NC)"
	@chmod +x scripts/test-ddos.sh
	@./scripts/test-ddos.sh

security-scan: ## Executa scan de segurança
	@echo "$(RED)🔍 Executando scan de segurança...$(NC)"
	@chmod +x scripts/security-scan.sh
	@./scripts/security-scan.sh

backup: ## Cria backup dos dados
	@echo "$(BLUE)💾 Criando backup...$(NC)"
	@chmod +x scripts/backup.sh
	@./scripts/backup.sh

restore: ## Restaura backup dos dados
	@echo "$(BLUE)📥 Restaurando backup...$(NC)"
	@chmod +x scripts/restore.sh
	@./scripts/restore.sh

# Comandos de desenvolvimento
dev-setup: ## Setup para desenvolvimento local
	@echo "$(BLUE)🛠️  Setup para desenvolvimento...$(NC)"
	@chmod +x scripts/dev-setup.sh
	@./scripts/dev-setup.sh

build-images: ## Constrói e faz push das imagens Docker
	@echo "$(BLUE)🐳 Construindo e fazendo push das imagens Docker...$(NC)"
	@chmod +x scripts/build-images.sh
	@./scripts/build-images.sh

push-images: ## Faz push das imagens para DockerHub
	@echo "$(BLUE)📤 Fazendo push das imagens...$(NC)"
	@chmod +x scripts/push-images.sh
	@./scripts/push-images.sh

# Comandos de monitoramento
monitor: ## Inicia monitoramento do cluster
	@echo "$(BLUE)📈 Iniciando monitoramento...$(NC)"
	@chmod +x scripts/monitor.sh
	@./scripts/monitor.sh

# Comandos de troubleshooting
troubleshoot: ## Executa diagnóstico do cluster
	@echo "$(YELLOW)🔧 Executando diagnóstico...$(NC)"
	@chmod +x scripts/troubleshoot.sh
	@./scripts/troubleshoot.sh

# Comandos de certificados
generate-certs: ## Gera certificados self-signed
	@echo "$(BLUE)🔐 Gerando certificados...$(NC)"
	@chmod +x scripts/generate-certs.sh
	@./scripts/generate-certs.sh
