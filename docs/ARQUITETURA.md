# Arquitetura - CloudWalk Desafio

## 📋 Visão Geral

Este documento descreve a arquitetura completa da aplicação File Sharing, incluindo as decisões de design, componentes e fluxo de dados.

## 🏗️ Arquitetura Geral

### Diagrama de Alto Nível

```
┌─────────────────────────────────────────────────────────────────┐
│                        Kubernetes Cluster                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   ArgoCD        │  │   Ingress       │  │   Monitoring    │  │
│  │   (GitOps)      │  │   Controller    │  │   & Logging     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│           │                     │                     │          │
│           └─────────────────────┼─────────────────────┘          │
│                                 │                                │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    File Sharing App                        │  │
│  │  ┌─────────────────┐    ┌─────────────────┐                │  │
│  │  │   Frontend      │    │   Backend       │                │  │
│  │  │   (React)       │◄──►│   (Node.js)     │                │  │
│  │  │   Port: 3000    │    │   Port: 3000    │                │  │
│  │  └─────────────────┘    └─────────────────┘                │  │
│  │           │                       │                        │  │
│  │           └───────────────────────┼────────────────────────┘  │
│  │                                   │                           │
│  │  ┌─────────────────────────────────────────────────────────┐  │
│  │  │                   Storage Layer                         │  │
│  │  │  ┌─────────────────┐  ┌─────────────────┐              │  │
│  │  │  │   PVC           │  │   ConfigMaps    │              │  │
│  │  │  │   (Files)       │  │   & Secrets     │              │  │
│  │  │  └─────────────────┘  └─────────────────┘              │  │
│  │  └─────────────────────────────────────────────────────────┘  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🧩 Componentes da Arquitetura

### 1. **Infraestrutura Base**

#### **Kubernetes Cluster (Minikube)**
- **Propósito**: Orquestração de containers e gerenciamento de recursos
- **Versão**: v1.28.0
- **Configuração**: Single-node cluster para desenvolvimento
- **Recursos**: CPU, memória e storage gerenciados pelo minikube

#### **ArgoCD (GitOps)**
- **Propósito**: Deploy automatizado baseado em Git
- **Versão**: v2.x
- **Funcionalidades**:
  - Sincronização automática de mudanças
  - Rollback automático
  - Monitoramento de health
  - Interface web para gerenciamento

#### **NGINX Ingress Controller**
- **Propósito**: Roteamento de tráfego HTTP/HTTPS
- **Funcionalidades**:
  - Load balancing
  - SSL/TLS termination
  - Path-based routing
  - Rate limiting

### 2. **Camada de Aplicação**

#### **Frontend (React)**
- **Tecnologia**: React 18 + Vite
- **Porta**: 3000
- **Responsabilidades**:
  - Interface de usuário
  - Upload/download de arquivos
  - Gerenciamento de estado
  - Comunicação com backend via API

**Estrutura do Frontend:**
```
app/frontend/
├── src/
│   ├── components/     # Componentes React
│   ├── pages/         # Páginas da aplicação
│   ├── hooks/         # Custom hooks
│   └── styles/        # Estilos CSS
├── public/            # Arquivos estáticos
└── package.json       # Dependências
```

#### **Backend (Node.js)**
- **Tecnologia**: Node.js + Express
- **Porta**: 3000
- **Responsabilidades**:
  - API REST
  - Processamento de arquivos
  - Validação de dados
  - Gerenciamento de storage

**Estrutura do Backend:**
```
app/backend/
├── src/
│   ├── controllers/   # Controladores da API
│   ├── middleware/    # Middlewares
│   ├── utils/         # Utilitários
│   └── config/        # Configurações
├── Dockerfile         # Containerização
└── package.json       # Dependências
```

### 3. **Camada de Storage**

#### **Storage Configuration**
- **Configuração Atual**: PVC habilitado por padrão
- **Tipo**: Persistent Volume Claim (PVC)
- **Capacidade**: 10Gi configurável via Helm
- **Acesso**: ReadWriteMany
- **Nota**: Para demo, pode ser desabilitado usando `storage.persistentVolume.enabled: false`

#### **⚠️ Importante: Persistência de Dados**

**Configuração Atual (Funcionando Corretamente):**
- ✅ PVC está habilitado por padrão
- ✅ Arquivos são persistidos entre restarts de pods
- ✅ Dados sobrevivem a reinicializações do cluster
- ✅ Testado e confirmado funcionamento

**Para Demo Simples (Sem Persistência):**
```yaml
storage:
  persistentVolume:
    enabled: false  # Usa emptyDir (temporário)
```

**Implicações do emptyDir:**
- ✅ **Vantagem**: Setup mais simples para demo
- ❌ **Desvantagem**: Arquivos são perdidos quando o pod é reiniciado
- ❌ **Desvantagem**: Não funciona com múltiplas réplicas

**Para Produção (Recomendado):**
```yaml
storage:
  persistentVolume:
    enabled: true
    size: "100Gi"
    storageClass: "fast-ssd"
    accessMode: ReadWriteMany
```

**🔍 Se Você Está Vendo Perda de Arquivos:**
1. Verifique se o PVC está `Bound`: `kubectl get pvc -n file-sharing`
2. Verifique se o volume está montado: `kubectl describe pod -n file-sharing <pod-name>`
3. Teste manualmente: criar arquivo → deletar pod → verificar se arquivo persiste
4. Pode ser problema de interface/UI, não do storage

#### **ConfigMaps e Secrets**
- **ConfigMaps**: Configurações não-sensíveis
- **Secrets**: Dados sensíveis (chaves, senhas)
- **Gerenciamento**: Via Kubernetes

## 🔄 Fluxo de Dados

### 1. **Upload de Arquivo**
```
Usuário → Frontend → Backend → Storage (PVC)
   ↓         ↓         ↓           ↓
1. Seleciona  2. Envia via   3. Valida e   4. Salva no
   arquivo     FormData       processa      volume
```

### 2. **Download de Arquivo**
```
Usuário → Frontend → Backend → Storage (PVC)
   ↓         ↓         ↓           ↓
1. Clica no  2. Requisita   3. Busca no    4. Retorna
   arquivo    download       storage        arquivo
```

### 3. **Deploy via GitOps**
```
Git → ArgoCD → Kubernetes → Aplicação
 ↓      ↓         ↓           ↓
1. Push  2. Detecta  3. Aplica   4. Deploy
   code   mudanças   manifests   automático
```

## 🎯 Decisões de Design

### 1. **Por que Kubernetes?**
- **Escalabilidade**: Fácil escalar horizontalmente
- **Portabilidade**: Funciona em qualquer cloud
- **Orquestração**: Gerenciamento automático de containers
- **Ecosystem**: Ricas ferramentas e integrações

### 2. **Por que GitOps com ArgoCD?**
- **Declarativo**: Estado desejado no Git
- **Auditável**: Histórico completo de mudanças
- **Automático**: Deploy sem intervenção manual
- **Rollback**: Reversão rápida de problemas

### 3. **Por que Helm?**
- **Templating**: Reutilização de configurações
- **Versionamento**: Controle de versões
- **Packaging**: Empacotamento de aplicações
- **Ecosystem**: Padrão da comunidade

### 4. **Por que Minikube?**
- **Desenvolvimento**: Ambiente local completo
- **Compatibilidade**: Mesmo comportamento do Kubernetes
- **Simplicidade**: Setup rápido e fácil
- **Recursos**: CPU, memória e storage integrados

## 🔒 Considerações de Segurança

### 1. **Network Security**
- **Network Policies**: Isolamento de rede
- **Ingress Security**: TLS e rate limiting
- **Service Mesh**: Comunicação segura entre serviços

### 2. **Container Security**
- **Security Contexts**: Não rodar como root
- **Image Scanning**: Vulnerabilidades em containers
- **Resource Limits**: Prevenção de DoS

### 3. **Data Security**
- **Encryption**: Dados em trânsito e repouso
- **Access Control**: RBAC e Service Accounts
- **Audit Logging**: Rastreamento de ações

## 📊 Monitoramento e Observabilidade

### 1. **Logs**
- **Application Logs**: Logs da aplicação
- **System Logs**: Logs do Kubernetes
- **Access Logs**: Logs de acesso

### 2. **Métricas**
- **Resource Metrics**: CPU, memória, storage
- **Application Metrics**: Requests, errors, latency
- **Business Metrics**: Uploads, downloads, users

### 3. **Alerting**
- **Resource Alerts**: Alta utilização
- **Error Alerts**: Falhas na aplicação
- **Security Alerts**: Tentativas de acesso não autorizado

## 🚀 Escalabilidade

### 1. **Horizontal Scaling**
- **Pods**: Múltiplas réplicas
- **Services**: Load balancing automático
- **Ingress**: Distribuição de carga

### 2. **Vertical Scaling**
- **Resources**: CPU e memória
- **Storage**: Capacidade de volume
- **Network**: Largura de banda

### 3. **Auto Scaling**
- **HPA**: Horizontal Pod Autoscaler
- **VPA**: Vertical Pod Autoscaler
- **Cluster Autoscaler**: Escalação do cluster

## 🔧 Configuração e Customização

### 1. **Variáveis de Ambiente**
- **ConfigMaps**: Configurações da aplicação
- **Secrets**: Dados sensíveis
- **Helm Values**: Personalização via Helm

### 2. **Recursos**
- **CPU/Memory**: Limites e requests
- **Storage**: Capacidade e tipo
- **Network**: Bandwidth e QoS

### 3. **Deploy**
- **Replicas**: Número de pods
- **Strategy**: Rolling update
- **Health Checks**: Liveness e readiness

---

**Próximo**: [Configuração](CONFIGURACAO.md) - Detalhes sobre configurações do Helm e personalização
