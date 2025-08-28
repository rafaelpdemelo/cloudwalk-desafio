# Instalação - CloudWalk Desafio

## 📋 Visão Geral

Este documento fornece instruções detalhadas para instalar todas as ferramentas necessárias para executar o projeto File Sharing em diferentes sistemas operacionais.

## 🎯 Pré-requisitos

### **Requisitos Mínimos do Sistema**

| Componente | Mínimo | Recomendado |
|------------|--------|-------------|
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 4GB | 8GB+ |
| **Storage** | 20GB livre | 50GB+ livre |
| **Sistema Operacional** | Linux/macOS/Windows | Linux/macOS |

### **Versões das Ferramentas**

| Ferramenta | Versão Mínima | Versão Recomendada | Comando de Verificação |
|------------|---------------|-------------------|------------------------|
| **kubectl** | v1.28.0 | v1.28.0+ | `kubectl version --client` |
| **helm** | v3.12.0 | v3.12.0+ | `helm version` |
| **minikube** | v1.31.0 | v1.31.0+ | `minikube version` |
| **argocd** | v2.8.0 | v2.8.0+ | `argocd version` |
| **docker** | v20.10.0 | v24.0.0+ | `docker --version` |
| **openssl** | v1.1.1 | v3.0.0+ | `openssl version` |

## 🐧 Linux (Ubuntu/Debian)

### **1. Atualizar Sistema**

```bash
sudo apt update && sudo apt upgrade -y
```

### **2. Instalar Dependências Base**

```bash
# Instalar dependências básicas
sudo apt install -y \
  curl \
  wget \
  git \
  unzip \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release
```

### **3. Docker**

```bash
# Adicionar repositório Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Iniciar e habilitar Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verificar instalação
docker --version
```

### **4. Kubernetes CLI (kubectl)**

```bash
# Baixar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Instalar kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verificar instalação
kubectl version --client
```

### **5. Helm**

```bash
# Adicionar repositório Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# Instalar Helm
sudo apt update
sudo apt install helm

# Verificar instalação
helm version
```

### **6. Minikube**

```bash
# Baixar Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Instalar Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verificar instalação
minikube version
```

### **7. ArgoCD CLI**

```bash
# Baixar ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

# Instalar ArgoCD CLI
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Limpar arquivo temporário
rm argocd-linux-amd64

# Verificar instalação
argocd version
```

### **8. OpenSSL**

```bash
# Instalar OpenSSL
sudo apt install -y openssl

# Verificar instalação
openssl version
```

## 🍎 macOS

### **1. Homebrew (se não instalado)**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### **2. Docker Desktop**

```bash
# Instalar Docker Desktop
brew install --cask docker

# Iniciar Docker Desktop
open /Applications/Docker.app

# Verificar instalação
docker --version
```

### **3. Kubernetes CLI (kubectl)**

```bash
# Instalar kubectl
brew install kubectl

# Verificar instalação
kubectl version --client
```

### **4. Helm**

```bash
# Instalar Helm
brew install helm

# Verificar instalação
helm version
```

### **5. Minikube**

```bash
# Instalar Minikube
brew install minikube

# Verificar instalação
minikube version
```

### **6. ArgoCD CLI**

```bash
# Instalar ArgoCD CLI
brew install argocd

# Verificar instalação
argocd version
```

### **7. OpenSSL**

```bash
# Instalar OpenSSL
brew install openssl

# Verificar instalação
openssl version
```

## 🪟 Windows

### **1. WSL2 (Recomendado)**

```powershell
# Habilitar WSL
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Reiniciar computador
# Depois instalar WSL2
wsl --install
```

### **2. Docker Desktop**

1. Baixar [Docker Desktop para Windows](https://www.docker.com/products/docker-desktop)
2. Instalar e configurar
3. Habilitar WSL2 integration
4. Verificar instalação:
   ```powershell
   docker --version
   ```

### **3. Kubernetes CLI (kubectl)**

```powershell
# Baixar kubectl
Invoke-WebRequest -Uri "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe" -OutFile "kubectl.exe"

# Mover para PATH
Move-Item kubectl.exe C:\Windows\System32\

# Verificar instalação
kubectl version --client
```

### **4. Helm**

```powershell
# Instalar via Chocolatey
choco install kubernetes-helm

# Ou baixar manualmente
Invoke-WebRequest -Uri "https://get.helm.sh/helm-v3.12.0-windows-amd64.zip" -OutFile "helm.zip"
Expand-Archive helm.zip -DestinationPath "C:\helm"
$env:PATH += ";C:\helm\windows-amd64"
```

### **5. Minikube**

```powershell
# Instalar via Chocolatey
choco install minikube

# Ou baixar manualmente
Invoke-WebRequest -Uri "https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe" -OutFile "minikube.exe"
Move-Item minikube.exe C:\Windows\System32\
```

### **6. ArgoCD CLI**

```powershell
# Baixar ArgoCD CLI
Invoke-WebRequest -Uri "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-windows-amd64.exe" -OutFile "argocd.exe"
Move-Item argocd.exe C:\Windows\System32\
```

## 🔧 Configuração Pós-Instalação

### **1. Configurar Docker**

```bash
# Verificar se Docker está rodando
docker ps

# Configurar registry (opcional)
docker login
```

### **2. Configurar Minikube**

```bash
# Iniciar Minikube com configurações recomendadas
minikube start \
  --profile cloudwalk-desafio \
  --driver=docker \
  --cpus=4 \
  --memory=8192 \
  --disk-size=50g \
  --addons=ingress \
  --addons=metrics-server

# Verificar status
minikube status --profile cloudwalk-desafio
```

### **3. Configurar kubectl**

```bash
# Verificar contexto
kubectl config current-context

# Verificar clusters
kubectl config get-clusters

# Verificar configuração
kubectl cluster-info
```

### **4. Configurar Helm**

```bash
# Adicionar repositórios necessários
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Verificar repositórios
helm repo list
```

## 🧪 Verificação da Instalação

### **Script de Verificação**

Crie um arquivo `verify-installation.sh`:

```bash
#!/bin/bash

echo "🔍 Verificando instalação das ferramentas..."

# Verificar Docker
echo "🐳 Docker:"
docker --version

# Verificar kubectl
echo "📦 kubectl:"
kubectl version --client

# Verificar Helm
echo "⚓ Helm:"
helm version

# Verificar Minikube
echo "🚀 Minikube:"
minikube version

# Verificar ArgoCD
echo "🔄 ArgoCD:"
argocd version

# Verificar OpenSSL
echo "🔐 OpenSSL:"
openssl version

echo "✅ Verificação concluída!"
```

Execute:
```bash
chmod +x verify-installation.sh
./verify-installation.sh
```

## 🚀 Setup Inicial do Projeto

### **1. Clone do Repositório**

```bash
git clone <repository-url>
cd cloudwalk-desafio
```

### **2. Setup Automático**

```bash
# Executar setup completo
make setup

# Verificar status
make status
```

### **3. Verificar Aplicação**

```bash
# Configurar port-forward
make port-forward

# Acessar aplicação
# Frontend: http://localhost:8080
# ArgoCD: http://localhost:8081
```

## 🛠️ Troubleshooting

### **Problemas Comuns**

#### **1. Docker não inicia**

**Linux:**
```bash
# Verificar status
sudo systemctl status docker

# Reiniciar Docker
sudo systemctl restart docker

# Verificar permissões
sudo usermod -aG docker $USER
newgrp docker
```

**macOS:**
```bash
# Reiniciar Docker Desktop
osascript -e 'quit app "Docker"'
open /Applications/Docker.app
```

**Windows:**
```powershell
# Reiniciar Docker Desktop
Stop-Process -Name "Docker Desktop"
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

#### **2. Minikube não inicia**

```bash
# Limpar e reiniciar
minikube delete --profile cloudwalk-desafio
minikube start --profile cloudwalk-desafio

# Verificar logs
minikube logs --profile cloudwalk-desafio
```

#### **3. kubectl não conecta**

```bash
# Verificar contexto
kubectl config current-context

# Mudar contexto se necessário
kubectl config use-context cloudwalk-desafio

# Verificar cluster
kubectl cluster-info
```

#### **4. Helm não funciona**

```bash
# Verificar configuração
helm env

# Atualizar repositórios
helm repo update

# Verificar versão
helm version
```

### **Logs de Debug**

```bash
# Logs do Minikube
minikube logs --profile cloudwalk-desafio

# Logs do Docker
docker system info

# Logs do Kubernetes
kubectl get events --all-namespaces
```

## 📚 Recursos Adicionais

### **Documentação Oficial**

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

### **Tutoriais**

- [Kubernetes Tutorial](https://kubernetes.io/docs/tutorials/)
- [Helm Tutorial](https://helm.sh/docs/intro/quickstart/)
- [Docker Tutorial](https://docs.docker.com/get-started/)

### **Comunidade**

- [Kubernetes Slack](https://slack.k8s.io/)
- [Docker Community](https://www.docker.com/community/)
- [Helm Community](https://helm.sh/community/)

## 🔄 Atualizações

### **Atualizar Ferramentas**

```bash
# Linux (Ubuntu/Debian)
sudo apt update && sudo apt upgrade

# macOS
brew update && brew upgrade

# Windows
choco upgrade all
```

### **Atualizar Projeto**

```bash
# Atualizar repositório
git pull origin main

# Reaplicar configurações
make setup
```

---

**Próximo**: [Deploy](DEPLOY.md) - Processo de deploy e GitOps com ArgoCD
