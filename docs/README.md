# CloudWalk Desafio - File Sharing App

## 📋 Descrição

Aplicação de compartilhamento de arquivos segura implementada com Kubernetes + GitOps (ArgoCD) para deploy local.

## 🎯 Objetivos do Desafio

- ✅ Set up básico de infraestrutura Kubernetes
- ✅ GitOps com ArgoCD
- ✅ Deploy local (minikube)
- ✅ Aplicação web com TLS (self-signed)
- ✅ Práticas de segurança implementadas

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Storage       │
│   (React)       │◄──►│   (Node.js)     │◄──►│   (PVC)         │
│   Port: 3000    │    │   Port: 3000    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Ingress       │
                    │   (NGINX)       │
                    │   TLS: 443      │
                    └─────────────────┘
```

## 🛠️ Tecnologias Utilizadas

### Infraestrutura
- **Kubernetes**: v1.28.0
- **Minikube**: Cluster local
- **Helm**: v3.x (Gerenciamento de pacotes)
- **ArgoCD**: v2.x (GitOps)

### Aplicação
- **Frontend**: React + Vite
- **Backend**: Node.js + Express
- **Ingress**: NGINX Ingress Controller
- **TLS**: Certificados self-signed

### Segurança
- **SecurityContext**: Configurado para todos os pods
- **NetworkPolicy**: Isolamento de rede
- **RBAC**: Controle de acesso baseado em roles
- **PodSecurityPolicy**: Políticas de segurança

## 📋 Pré-requisitos

### Versões das Ferramentas

| Ferramenta | Versão Mínima | Comando de Verificação |
|------------|---------------|------------------------|
| kubectl    | v1.28.0       | `kubectl version --client` |
| helm       | v3.12.0       | `helm version` |
| minikube   | v1.31.0       | `minikube version` |
| argocd     | v2.8.0        | `argocd version` |
| docker     | v20.10.0      | `docker --version` |
| openssl    | v1.1.1        | `openssl version` |

### Instalação das Dependências

#### macOS (Homebrew)
```bash
# Kubernetes CLI
brew install kubectl

# Helm
brew install helm

# Minikube
brew install minikube

# ArgoCD CLI
brew install argocd

# Docker Desktop
brew install --cask docker
```

#### Linux (Ubuntu/Debian)
```bash
# Kubernetes CLI
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update && sudo apt-get install helm

# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

#### Windows (Chocolatey)
```powershell
# Kubernetes CLI
choco install kubernetes-cli

# Helm
choco install kubernetes-helm

# Minikube
choco install minikube

# ArgoCD CLI
choco install argocd
```

## 🚀 Quick Start

### 1. Setup Completo
```bash
# Clone o repositório
git clone https://github.com/rafaelpdemelo/cloudwalk-desafio.git
cd cloudwalk-desafio

# Execute o setup completo
make setup
```

### 2. Verificar Status
```bash
# Verificar status do cluster e aplicações
make status
```

### 3. Acessar a Aplicação
```bash
# Configurar port-forward
make port-forward

# Acessar no navegador
# https://file-sharing.local
```

### 4. Acessar ArgoCD
```bash
# Credenciais do ArgoCD
# URL: https://localhost:8080
# Usuário: admin
# Senha: (será exibida no setup)
```

## 📖 Comandos Disponíveis

### Comandos Principais
```bash
make help              # Mostra todos os comandos disponíveis
make setup             # Setup completo do ambiente
make cleanup           # Remove completamente o ambiente
make status            # Verifica status do cluster
make logs              # Mostra logs das aplicações
```

### Comandos de Desenvolvimento
```bash
make dev-setup         # Setup para desenvolvimento
make build-images      # Constrói imagens Docker
make push-images       # Faz push das imagens
```

### Comandos de Segurança
```bash
make test-ddos         # Testa proteção DDOS
make security-scan     # Executa scan de segurança
```

### Comandos de Monitoramento
```bash
make monitor           # Inicia monitoramento
make troubleshoot      # Executa diagnóstico
```

### Comandos de Acesso
```bash
make port-forward      # Configura port-forward
make stop-port-forwards # Para port-forwards
```

## 🔧 Configuração

### Estrutura do Projeto
```
cloudwalk-desafio/
├── app/                    # Código da aplicação
│   ├── frontend/          # Frontend React
│   └── backend/           # Backend Node.js
├── helm/                  # Helm Charts
│   ├── templates/         # Templates Kubernetes
│   ├── Chart.yaml         # Metadados do Chart
│   └── values.yaml        # Configurações
├── argocd/               # Configurações ArgoCD
│   ├── application.yaml   # Aplicação ArgoCD
│   └── project.yaml       # Projeto ArgoCD
├── scripts/              # Scripts de automação
│   ├── Makefile          # Comandos principais
│   ├── setup.sh          # Setup completo
│   ├── cleanup.sh        # Cleanup completo
│   └── ...               # Outros scripts
└── docs/                 # Documentação
    └── README.md         # Este arquivo
```

### Configurações de Segurança

#### SecurityContext
- **runAsNonRoot**: true
- **readOnlyRootFilesystem**: true
- **allowPrivilegeEscalation**: false
- **capabilities.drop**: ["ALL"]

#### NetworkPolicy
- Isolamento de rede por namespace
- Apenas tráfego necessário permitido
- Bloqueio de acesso não autorizado

#### RBAC
- ServiceAccounts específicos
- Permissões mínimas necessárias
- Controle de acesso granular

## 🔐 Segurança

### Certificados TLS
- Certificados self-signed gerados automaticamente
- Validade: 365 dias
- Domínio: file-sharing.local

### Políticas de Segurança
- **PodSecurityPolicy**: Configurado
- **NetworkPolicy**: Implementado
- **SecurityContext**: Aplicado em todos os pods
- **RBAC**: Controle de acesso baseado em roles

### ArgoCD Security
- Projeto específico com políticas restritivas
- Apenas recursos necessários permitidos
- Sync windows configuradas
- Orphaned resources desabilitados

## 🐛 Troubleshooting

### Problemas Comuns

#### 1. Minikube não inicia
```bash
# Verificar se Docker está rodando
docker ps

# Limpar e reiniciar
minikube delete --profile=cloudwalk-desafio
make setup
```

#### 2. ArgoCD não sincroniza
```bash
# Verificar status da aplicação
kubectl get application -n argocd

# Verificar logs do ArgoCD
kubectl logs -n argocd deployment/argocd-server

# Forçar sync
argocd app sync file-sharing-app
```

#### 3. Certificado inválido
```bash
# Regenerar certificados
make generate-certs

# Verificar certificado
openssl x509 -in scripts/certs/tls.crt -text -noout
```

#### 4. Aplicação não acessível
```bash
# Verificar ingress
kubectl get ingress -n file-sharing

# Verificar serviços
kubectl get svc -n file-sharing

# Verificar pods
kubectl get pods -n file-sharing
```

### Logs Úteis
```bash
# Logs do frontend
kubectl logs -n file-sharing deployment/file-sharing-app-frontend

# Logs do backend
kubectl logs -n file-sharing deployment/file-sharing-app-backend

# Logs do ingress
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## 📊 Monitoramento

### Métricas Disponíveis
- **CPU/Memory**: HPA configurado
- **Logs**: Centralizados via kubectl
- **Health Checks**: Implementados

### Alertas
- **Pod Restarts**: Monitorados
- **Resource Usage**: HPA ativo
- **Network Issues**: NetworkPolicy

## 🔄 CI/CD

### Fluxo GitOps
1. **Push** para repositório
2. **ArgoCD** detecta mudanças
3. **Sync** automático
4. **Deploy** no cluster


Este projeto é parte do desafio técnico da CloudWalk.
