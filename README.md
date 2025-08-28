# CloudWalk Desafio - File Sharing App

## 📋 Visão Geral

Aplicação de compartilhamento de arquivos segura implementada com **Kubernetes + GitOps (ArgoCD)** para deploy local. Este projeto demonstra práticas modernas de DevOps, segurança e arquitetura de microsserviços.

## 🎯 Objetivos

- ✅ **Infraestrutura Kubernetes** completa com minikube
- ✅ **GitOps** com ArgoCD para deploy automatizado
- ✅ **Aplicação web** com TLS e práticas de segurança
- ✅ **Monitoramento** e observabilidade
- ✅ **Testes de segurança** automatizados

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

## 🚀 Quick Start

### Pré-requisitos

| Ferramenta | Versão Mínima | Instalação |
|------------|---------------|------------|
| kubectl    | v1.28.0       | [Instruções](docs/INSTALACAO.md#kubernetes-cli) |
| helm       | v3.12.0       | [Instruções](docs/INSTALACAO.md#helm) |
| minikube   | v1.31.0       | [Instruções](docs/INSTALACAO.md#minikube) |
| argocd     | v2.8.0        | [Instruções](docs/INSTALACAO.md#argocd) |
| docker     | v20.10.0      | [Instruções](docs/INSTALACAO.md#docker) |

### Deploy Rápido

```bash
# 1. Clone o repositório
git clone <repository-url>
cd cloudwalk-desafio

# 2. Setup completo (com persistência)
make setup

# 3. Verificar status
make status

# 4. Acessar aplicação
make port-forward
```

### Deploy para Demo (sem persistência)

```bash
# Para demo simples sem persistência de dados
helm install file-sharing-app ./helm -f helm/values-demo.yaml

# ⚠️ Nota: Arquivos serão perdidos quando o pod for reiniciado
```

## 📚 Documentação Completa

### 🏗️ [Arquitetura](docs/ARQUITETURA.md)
- Visão geral da arquitetura
- Componentes e suas responsabilidades
- Fluxo de dados
- Decisões de design

### ⚙️ [Configuração](docs/CONFIGURACAO.md)
- Configurações do Helm
- Variáveis de ambiente
- Configurações de segurança
- Personalização

### 🔒 [Segurança](docs/SEGURANCA.md)
- Políticas de segurança implementadas
- Configurações de TLS
- Network Policies
- RBAC e controle de acesso

### 🛠️ [Instalação](docs/INSTALACAO.md)
- Instalação em diferentes sistemas operacionais
- Configuração de ferramentas
- Troubleshooting

### 🚀 [Deploy](docs/DEPLOY.md)
- Processo de deploy
- GitOps com ArgoCD
- Monitoramento
- Rollback

### 🔧 [Troubleshooting](docs/TROUBLESHOOTING.md)
- Problemas comuns
- Soluções
- Logs e debugging

## 🛠️ Comandos Principais

```bash
# Setup completo
make setup

# Deploy da aplicação
make deploy

# Status e monitoramento
make status
make logs

# Testes de segurança
make test-sec

# Limpeza
make cleanup
```

## 💾 Storage e Persistência

### **Configuração Padrão (Com Persistência)**
- ✅ **PVC habilitado** por padrão
- ✅ **Arquivos persistidos** entre restarts
- ✅ **Dados sobrevivem** a reinicializações
- ✅ **Suporte a múltiplas réplicas**

### **Configuração Demo (Sem Persistência)**
- ⚠️ **emptyDir** para demonstrações simples
- ❌ **Arquivos perdidos** quando pod reinicia
- ❌ **Não funciona** com múltiplas réplicas
- ✅ **Setup mais simples** para demo

**Para usar demo sem persistência:**
```bash
helm install file-sharing-app ./helm -f helm/values-demo.yaml
```

## 📊 Status do Projeto

- ✅ **Infraestrutura**: Kubernetes + Minikube
- ✅ **GitOps**: ArgoCD configurado
- ✅ **Aplicação**: Frontend React + Backend Node.js
- ✅ **Segurança**: TLS, Network Policies, RBAC
- ✅ **Storage**: PVC configurável (persistente/não-persistente)
- ✅ **Monitoramento**: Logs e observabilidade

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

---

**Desenvolvido para o Desafio da vaga de Cloud Security Engineer da CloudWalk**
