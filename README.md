# CloudWalk File Sharing App

## Visão Geral

Aplicação segura de compartilhamento de arquivos com criptografia end-to-end, desenvolvida para demonstrar melhores práticas de segurança em Kubernetes com GitOps.

## Funcionalidades

- 📁 Upload seguro de arquivos com criptografia AES-256
- 🔐 Proteção por senha personalizada
- 🔗 Geração de links únicos com TTL
- 📥 Download com verificação de senha
- 🛡️ Rate limiting e validação de arquivos
- 📋 Logs de auditoria completos

## Componentes

- **Frontend**: React com interface responsiva
- **Backend**: Node.js API REST com criptografia
- **Proxy**: Nginx com TLS e security headers
- **Infraestrutura**: Kubernetes com Pod Security Standards
- **GitOps**: ArgoCD para deployment automatizado

## Recursos de Segurança

- ✅ Pod Security Standards (restricted)
- ✅ Network Policies
- ✅ RBAC (Role-Based Access Control)
- ✅ TLS end-to-end com certificados
- ✅ Criptografia AES-256 dos arquivos
- ✅ Rate limiting e input validation
- ✅ Security headers (CSP, HSTS, X-Frame-Options)
- ✅ Logs de auditoria estruturados

## 🚀 Quick Start para Avaliador

### ⚡ Execução Automatizada (1 comando):

```bash
# Configurar TODO o ambiente (100% automatizado)
./setup.sh
```

**Após executar, a aplicação estará AUTOMATICAMENTE disponível em:**
- **🌐 Aplicação**: http://localhost:8080
- **📊 ArgoCD**: https://localhost:8443 (usuário: admin)

### 📚 Repositório GitHub:
- **🌐 URL**: https://github.com/rafaelpdemelo/cloudwalk-desafio
- **🔄 GitOps**: ArgoCD sincronizado automaticamente

### 🧹 Limpeza:

```bash
# Limpar ambiente completamente
./cleanup.sh

# Parar apenas port-forwards (manter cluster)
./stop-port-forwards.sh
```

## Arquitetura

```
[Frontend React] → [Nginx Proxy] → [Backend API] → [PersistentVolume]
                       ↓
                  [TLS Certificate]
                       ↓
                  [ArgoCD GitOps]
```

## Estrutura do Projeto

```
cloudwalk-app/
├── setup.sh                 # Script de configuração completa
├── cleanup.sh               # Script de limpeza
├── app/                     # Código da aplicação
│   ├── backend/            # API Node.js
│   ├── frontend/           # Frontend React
│   └── proxy/              # Nginx proxy
├── k8s/                    # Manifests Kubernetes
├── argocd/                 # Configuração ArgoCD
└── certs/                  # Certificados TLS
```
