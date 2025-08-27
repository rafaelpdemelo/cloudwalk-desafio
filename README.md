# 🚀 Desafio CloudWalk - Secure File Sharing Platform

[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![GitOps](https://img.shields.io/badge/GitOps-ArgoCD-blue?style=for-the-badge&logo=argo&logoColor=white)](https://argo-cd.readthedocs.io/)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![React](https://img.shields.io/badge/react-%2320232a.svg?style=for-the-badge&logo=react&logoColor=%2361DAFB)](https://reactjs.org/)
[![Node.js](https://img.shields.io/badge/node.js-6DA55F?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)

> **Plataforma segura de compartilhamento de arquivos com criptografia end-to-end, implementada seguindo as melhores práticas de segurança em Kubernetes e GitOps.**

## 📋 Índice

- [🎯 Visão Geral](#-visão-geral)
- [🏗️ Arquitetura](#️-arquitetura)
- [⚡ Quick Start](#-quick-start)
- [🔐 Recursos de Segurança](#-recursos-de-segurança)
- [🛠️ Tecnologias](#️-tecnologias)
- [📁 Estrutura do Projeto](#-estrutura-do-projeto)
- [🎮 Demo](#-demo)
- [📊 Monitoramento](#-monitoramento)
- [🔧 Troubleshooting](#-troubleshooting)
- [📝 Documentação Adicional](#-documentação-adicional)

## 🎯 Visão Geral

Esta aplicação foi desenvolvida como resposta ao desafio técnico da CloudWalk, demonstrando competências em:

- **Desenvolvimento Full-Stack** com React + Node.js
- **Containerização** com Docker e multi-stage builds
- **Orquestração** com Kubernetes e Pod Security Standards
- **GitOps** com ArgoCD para deployment automatizado
- **Segurança** com criptografia, RBAC, Network Policies e TLS
- **Observabilidade** com logs estruturados e health checks

### 🎯 Funcionalidades Principais

| Funcionalidade | Descrição | Status |
|---|---|:---:|
| 📁 **Upload Seguro** | Criptografia AES-256 + validação de tipos | ✅ |
| 🔐 **Proteção por Senha** | Hash bcrypt + salt personalizado | ✅ |
| 🔗 **Links Únicos** | UUID v4 com TTL configurável | ✅ |
| 📥 **Download Verificado** | Descriptografia automática + logs | ✅ |
| 🛡️ **Rate Limiting** | Proteção contra ataques DDoS | ✅ |
| 📋 **Auditoria** | Logs estruturados JSON + timestamps | ✅ |
| 🔒 **TLS End-to-End** | Certificados auto-assinados + proxy | ✅ |
| 🚦 **Health Checks** | Monitoramento de pods + readiness | ✅ |

## 🏗️ Arquitetura

```mermaid
graph TB
    subgraph "Kubernetes Cluster"
        subgraph "Ingress Layer"
            ING[Nginx Ingress<br/>TLS Termination]
        end
        
        subgraph "Application Layer"
            FE[Frontend Pod<br/>React + Nginx]
            BE[Backend Pod<br/>Node.js API]
            PX[Proxy Pod<br/>Nginx + Security Headers]
        end
        
        subgraph "Storage Layer"
            PV[EmptyDir<br/>Encrypted Files<br/>(Demo Storage)]
        end
        
        subgraph "GitOps Layer"
            ARGO[ArgoCD<br/>Deployment Controller]
            REPO[GitHub Repository<br/>Source of Truth]
        end
    end
    
    USER[👤 User] --> ING
    ING --> FE
    FE --> PX
    PX --> BE
    BE --> PV
    
    REPO --> ARGO
    ARGO --> FE
    ARGO --> BE
    ARGO --> PX
    
    classDef frontend fill:#61dafb,stroke:#21759b,color:#000
    classDef backend fill:#68d391,stroke:#276749,color:#000
    classDef storage fill:#fbb6ce,stroke:#97266d,color:#000
    classDef gitops fill:#fd7f6f,stroke:#c53030,color:#fff
    
    class FE frontend
    class BE,PX backend
    class PV storage
    class ARGO,REPO gitops
```

### 🔄 Fluxo de Dados

1. **Upload**: React → Nginx Proxy → Node.js API → Criptografia AES-256 → EmptyDir (Para a Demo)
2. **Download**: Link único → Validação senha → Descriptografia → Stream do arquivo
3. **GitOps**: GitHub push → ArgoCD detect → Kubernetes sync → Rolling update

### 💾 Storage Strategy (Demo)

Para esta demonstração, utilizamos **EmptyDir** como solução de storage temporário:

- ✅ **Funcional**: Permite upload/download completo durante a demo
- ✅ **Simples**: Não requer configuração de storage persistente
- ✅ **Seguro**: Arquivos criptografados mesmo em storage temporário
- ⚠️ **Temporário**: Dados são perdidos quando o pod é reiniciado

> **Produção**: Em ambiente produtivo, recomenda-se usar PersistentVolumes com storage classes adequados (SSD, backup automático, etc.)

### 📦 Componentes

- **Frontend**: React com interface responsiva
- **Backend**: Node.js API REST com criptografia
- **Proxy**: Nginx com TLS e security headers
- **Infraestrutura**: Kubernetes com Pod Security Standards
- **GitOps**: ArgoCD para deployment automatizado

## ⚡ Quick Start

### 🚀 Setup Completo (1 comando)

```bash
cd cloudwalk-app
./setup.sh
```

O script automaticamente:
- ✅ Verifica dependências (Docker, Kubernetes, Git)
- ✅ Configura cluster Minikube com addons
- ✅ Gera certificados TLS auto-assinados
- ✅ Faz build e push das imagens Docker
- ✅ Instala e configura ArgoCD
- ✅ Aplica todas as configurações Kubernetes
- ✅ Configura port-forwards e expõe a aplicação

### 🌐 Acesso à Aplicação

Após o setup:

| Serviço | URL | Credenciais |
|---|---|---|
| **Aplicação Principal** | http://localhost:8080 | - |
| **ArgoCD Dashboard** | https://localhost:8443 | admin / [gerado dinamicamente] |
| **API Backend** | http://localhost:3001 | - |

### 📦 Pré-requisitos

- **Docker Desktop** (com login no DockerHub)
- **Minikube** ou cluster Kubernetes local
- **Git** configurado
- **Kubectl** instalado
- **Repositório GitHub** (público ou privado com token)

## 🚀 Quick Start para Avaliador

### ⚡ Execução Automatizada (1 comando)

```bash
# Configurar TODO o ambiente (com verificações interativas)
./setup.sh
```

**Durante a execução você será questionado sobre:**
1. **📋 Repositório GitHub**: Se já fez push do código
2. **🌐 URL do Repositório**: Link HTTPS do seu repositório GitHub  
3. **🔐 Visibilidade**: Se o repositório é público ou privado  
4. **🐳 Docker**: Se já está configurado e logado no DockerHub

**Após executar, a aplicação estará AUTOMATICAMENTE disponível em:**
- **🌐 Aplicação**: http://localhost:8080
- **📊 ArgoCD**: https://localhost:8443 (usuário: admin)

### 📚 Repositório GitHub:
- **🌐 URL**: https://github.com/rafaelpdemelo/cloudwalk-desafio
- **🔄 GitOps**: ArgoCD sincronizado automaticamente

### 🔐 Configuração Automática de Repositório:

Durante a execução do `setup.sh`, o script **automaticamente detecta** se o repositório é público ou privado:

#### 📋 **Repositório Público:**
- ✅ Configuração automática
- ✅ Sem necessidade de token
- ✅ ArgoCD acessa diretamente

#### 🔐 **Repositório Privado:**
O script solicitará interativamente:

1. **🔑 Personal Access Token do GitHub:**
   - Acesse: https://github.com/settings/tokens
   - Crie token com permissões: `repo`, `read:user`, `user:email`
   - Cole o token no prompt do script

2. **⚙️ Configuração Automática:**
   - Script cria `argocd/repo-secret.yaml` automaticamente
   - Aplica credenciais no ArgoCD
   - Configura sincronização com repositório privado

3. **✅ Verificação:**
   ```bash
   kubectl get applications -n argocd
   # Status: Synced + Healthy
   ```

> **Nota**: O arquivo `repo-secret.yaml` é automaticamente ignorado pelo Git por segurança.

### 🧹 Limpeza TOTAL:

```bash
# ⚠️  DESTRUIR COMPLETAMENTE todo o ambiente
./cleanup.sh

# Parar apenas port-forwards (manter cluster)
./stop-port-forwards.sh
```

**🚨 ATENÇÃO**: O script de limpeza é **DESTRUTIVO TOTAL** e remove:
- 💥 **TODO** o cluster Minikube
- 💥 **TODAS** as imagens Docker 
- 💥 **TODOS** os certificados
- 💥 **TODOS** os arquivos temporários
- 💥 **TODAS** as configurações
- 💥 **TODOS** os dados e volumes

Para confirmar a destruição, digite `y` quando solicitado.

### 🔧 Configuração do Docker:

**Antes de executar o setup, certifique-se que o Docker está configurado:**

```bash
# 1. Criar conta no DockerHub (se não tiver)
# Acesse: https://hub.docker.com

# 2. Fazer login local
docker login
```

**Se o setup pausar por problema do Docker, configure conforme as instruções exibidas e execute `./setup.sh` novamente.**

## 🔐 Recursos de Segurança

### 🛡️ Kubernetes Security

| Categoria | Implementação | Status |
|---|---|:---:|
| **Pod Security** | Pod Security Standards (restricted) | ✅ |
| **Network** | Network Policies + deny-all default | ✅ |
| **RBAC** | ServiceAccounts + ClusterRoles mínimos | ✅ |
| **Secrets** | Kubernetes Secrets + encryption at rest | ✅ |
| **Resources** | Limits + Requests definidos | ✅ |
| **Non-root** | Containers rodando como user 1001 | ✅ |

### 🔒 Application Security

| Categoria | Implementação | Status |
|---|---|:---:|
| **Encryption** | AES-256-GCM para arquivos | ✅ |
| **Password** | Bcrypt + salt + pepper | ✅ |
| **Rate Limiting** | Express-rate-limit + Redis | ✅ |
| **Input Validation** | Joi schemas + sanitização | ✅ |
| **Security Headers** | Helmet.js + CSP + HSTS | ✅ |
| **File Validation** | Magic numbers + whitelist | ✅ |
| **Audit Logs** | Winston + JSON structured | ✅ |

### 🔐 TLS/SSL

```bash
# Certificados gerados automaticamente
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -out ca.crt
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -out server.crt
```

## 🛠️ Tecnologias

### Frontend Stack
- **React 18** - Framework UI moderno
- **Vite** - Build tool rápido
- **React Router** - Roteamento SPA
- **Axios** - Cliente HTTP
- **React Dropzone** - Upload de arquivos
- **React Toastify** - Notificações

### Backend Stack
- **Node.js 18+** - Runtime JavaScript
- **Express.js** - Framework web
- **Multer** - Upload middleware
- **Winston** - Logging estruturado
- **Joi** - Validação de schemas
- **Bcrypt** - Hash de senhas
- **Crypto** - Criptografia nativa

### Infrastructure Stack
- **Kubernetes** - Orquestração de containers
- **ArgoCD** - GitOps deployment
- **Nginx** - Proxy reverso + load balancer
- **Docker** - Containerização
- **Minikube** - Cluster local

## 📁 Estrutura do Projeto

```
desafio/
├── 📄 README.md                    # Este arquivo
└── cloudwalk-app/                  # Aplicação principal
    ├── 🚀 setup.sh                 # Setup automatizado
    ├── 🧹 cleanup.sh               # Limpeza completa
    ├── ⏹️  stop-port-forwards.sh   # Parar port-forwards
    ├── 📖 README.md                # Documentação da app
    │
    ├── 📦 app/                     # Código fonte
    │   ├── 🎨 frontend/           # React SPA
    │   ├── ⚙️  backend/            # Node.js API
    │   └── 🔒 proxy/              # Nginx proxy
    │
    ├── ☸️  k8s/                    # Manifests Kubernetes
    │   ├── deployments/           # Deployments
    │   ├── services/              # Services
    │   ├── ingress/               # Ingress rules
    │   ├── security/              # RBAC + Network Policies
    │   ├── storage/               # EmptyDir (Apenas para a demo)
    │   └── namespace/             # Namespaces
    │
    ├── 🔄 argocd/                 # GitOps configuration
    │   ├── application.yaml       # ArgoCD app definition
    │   └── repo-secret-template.yaml # Repo credentials template
    │
    └── 🔐 certs/                  # Certificados TLS
        ├── ca.crt                 # Certificate Authority
        ├── server.crt             # Server certificate
        └── server.key             # Private key
```

## 🎮 Demo

### 📤 Upload de Arquivo

1. Acesse http://localhost:8080
2. Clique em "Upload File"
3. Selecione arquivo (max 50MB)
4. Defina senha personalizada
5. Configure TTL (1h - 24h)
6. Receba link único criptografado

### 📥 Download de Arquivo

1. Acesse link recebido
2. Digite senha correta
3. Arquivo é descriptografado automaticamente
4. Download inicia imediatamente

> **⚠️ Nota da Demo**: Os arquivos são armazenados em EmptyDir (storage temporário). Arquivos serão perdidos se o pod for reiniciado. Ideal para demonstração e testes.

### 🔍 Logs de Auditoria

```bash
# Ver logs em tempo real
kubectl logs -f deployment/backend -n file-sharing

# Exemplo de log estruturado
{
  "timestamp": "2024-01-15T10:30:45.123Z",
  "level": "info",
  "message": "File uploaded successfully",
  "fileId": "550e8400-e29b-41d4-a716-446655440000",
  "fileName": "document.pdf",
  "fileSize": 2048000,
  "clientIP": "192.168.1.100",
  "userAgent": "Mozilla/5.0...",
  "correlationId": "req-12345"
}
```

## 📊 Monitoramento

### 🏥 Health Checks

```bash
# Verificar status da aplicação
kubectl get pods -n file-sharing
kubectl get services -n file-sharing
kubectl get ingress -n file-sharing

# Verificar ArgoCD
kubectl get applications -n argocd
```

### 📈 Métricas de Performance

| Métrica | Valor Esperado | Comando |
|---|---|---|
| **Pod CPU** | < 100m | `kubectl top pods -n file-sharing` |
| **Pod Memory** | < 128Mi | `kubectl top pods -n file-sharing` |
| **Response Time** | < 200ms | `curl -w "%{time_total}" localhost:8080` |
| **Upload Speed** | > 10MB/s | Teste com arquivo de 50MB |

### 🚨 Alertas e Logs

```bash
# Monitorar logs de erro
kubectl logs -f deployment/backend -n file-sharing --tail=100 | grep ERROR

# Verificar events do cluster
kubectl get events -n file-sharing --sort-by='.lastTimestamp'

# Status do ArgoCD
kubectl get app file-sharing-app -n argocd -o yaml
```

## 🔧 Troubleshooting

### ❓ Problemas Comuns

<details>
<summary><strong>🚫 "Port already in use"</strong></summary>

```bash
# Verificar processos usando as portas
lsof -i :8080 -i :8443 -i :3001

# Parar port-forwards ativos
./stop-port-forwards.sh

# Ou matar processos específicos
pkill -f "kubectl port-forward"
```
</details>

<details>
<summary><strong>🐳 "Docker build failed"</strong></summary>

```bash
# Verificar se está logado no DockerHub
docker info | grep Username

# Fazer login se necessário
docker login

# Verificar espaço em disco
docker system df
docker system prune -af  # Limpar se necessário
```
</details>

<details>
<summary><strong>☸️ "Pod in CrashLoopBackOff"</strong></summary>

```bash
# Verificar logs do pod
kubectl logs -f <pod-name> -n file-sharing

# Verificar events
kubectl describe pod <pod-name> -n file-sharing

# Verificar recursos
kubectl top pods -n file-sharing
```
</details>

<details>
<summary><strong>🔄 "ArgoCD Sync Failed"</strong></summary>

```bash
# Verificar status da aplicação
kubectl get app file-sharing-app -n argocd

# Ver detalhes do erro
kubectl describe app file-sharing-app -n argocd

# Forçar sync manual
kubectl patch app file-sharing-app -n argocd --type merge -p '{"operation":{"syncPolicy":{"automated":null}}}'
```
</details>

### 🔄 Reset Completo

```bash
# ⚠️ ATENÇÃO: Destroi TUDO
./cleanup.sh

# Recriar ambiente do zero
./setup.sh
```

## 📝 Documentação Adicional

### 📚 Recursos de Aprendizado

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)
- [React Security Guidelines](https://react.dev/learn/security)

### 🔗 Links Úteis

- **GitHub Repository**: [cloudwalk-desafio](https://github.com/rafaelpdemelo/cloudwalk-desafio)
- **Docker Images**: [rafaelpdemelo/desafioFileSharing](https://hub.docker.com/r/rafaelpdemelo/desafiofilesharing)
- **Live Demo**: http://localhost:8080 (após setup)

### 📧 Contato

- **Desenvolvedor**: Rafael Pereira de Melo
- **GitHub**: [@rafaelpdemelo](https://github.com/rafaelpdemelo)
- **LinkedIn**: [Rafael Pereira de Melo](https://linkedin.com/in/rafaelpdemelo)

---

<div align="center">

**🚀 Desenvolvido para o Desafio CloudWalk**

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat&logo=kubernetes&logoColor=white)
![GitOps](https://img.shields.io/badge/GitOps-ArgoCD-blue?style=flat&logo=argo&logoColor=white)
![Security](https://img.shields.io/badge/Security-First-green?style=flat&logo=shield&logoColor=white)

</div>
