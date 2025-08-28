# Deploy - CloudWalk Desafio

## 📋 Visão Geral

Este documento descreve o processo de deploy da aplicação File Sharing usando GitOps com ArgoCD, incluindo configurações, monitoramento e rollback.

## 🎯 GitOps com ArgoCD

### **O que é GitOps?**

GitOps é uma metodologia onde o Git é a fonte única da verdade para deploy e gerenciamento de infraestrutura. Todas as mudanças são versionadas e auditáveis.

### **Por que ArgoCD?**

- **Declarativo**: Estado desejado no Git
- **Automático**: Sincronização contínua
- **Auditável**: Histórico completo
- **Rollback**: Reversão rápida
- **Multi-cluster**: Gerenciamento centralizado

## 🏗️ Arquitetura de Deploy

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Git           │    │   ArgoCD        │    │   Kubernetes    │
│   Repository    │───►│   Server        │───►│   Cluster       │
│                 │    │                 │    │                 │
│   - Manifests   │    │   - Sync        │    │   - Pods        │
│   - Helm Charts │    │   - Monitor     │    │   - Services    │
│   - Configs     │    │   - Rollback    │    │   - Ingress     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Processo de Deploy

### **1. Preparação do Ambiente**

```bash
# Verificar se o cluster está pronto
kubectl cluster-info

# Verificar se o ArgoCD está instalado
kubectl get pods -n argocd

# Verificar se o Ingress Controller está ativo
kubectl get pods -n ingress-nginx
```

### **2. Configuração do ArgoCD**

```bash
# Acessar ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8081:443

# Login no ArgoCD
argocd login localhost:8081 --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
```

### **3. Criação do Projeto**

```yaml
# argocd/project.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: file-sharing
  namespace: argocd
spec:
  description: File Sharing Application Project
  
  # Repositórios permitidos
  sourceRepos:
    - 'https://github.com/cloudwalk/file-sharing-app'
  
  # Destinos permitidos
  destinations:
    - namespace: file-sharing
      server: https://kubernetes.default.svc
  
  # Recursos permitidos
  clusterResourceWhitelist:
    - group: ''
      kind: Namespace
    - group: 'networking.k8s.io'
      kind: NetworkPolicy
  
  namespaceResourceWhitelist:
    - group: ''
      kind: ConfigMap
    - group: ''
      kind: Secret
    - group: ''
      kind: Service
    - group: ''
      kind: PersistentVolumeClaim
    - group: 'apps'
      kind: Deployment
    - group: 'networking.k8s.io'
      kind: Ingress
  
  # Políticas de segurança
  orphanedResources:
    warn: true
  
  # Sync windows
  syncWindows:
    - kind: allow
      schedule: '0 0 * * *'
      duration: '24h'
      applications:
        - 'file-sharing-app'
```

### **4. Criação da Aplicação**

```yaml
# argocd/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: file-sharing-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: file-sharing
  
  # Fonte do repositório
  source:
    repoURL: https://github.com/cloudwalk/file-sharing-app
    targetRevision: HEAD
    path: helm
  
  # Destino
  destination:
    server: https://kubernetes.default.svc
    namespace: file-sharing
  
  # Configurações de sync
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    
    # Retry em caso de falha
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### **5. Deploy da Aplicação**

```bash
# Aplicar configurações
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application.yaml

# Verificar status
argocd app list
argocd app get file-sharing-app
```

## 📊 Monitoramento do Deploy

### **1. Status da Aplicação**

```bash
# Verificar status geral
argocd app get file-sharing-app

# Verificar recursos
argocd app resources file-sharing-app

# Verificar logs
argocd app logs file-sharing-app
```

### **2. Monitoramento via kubectl**

```bash
# Verificar pods
kubectl get pods -n file-sharing

# Verificar services
kubectl get svc -n file-sharing

# Verificar ingress
kubectl get ingress -n file-sharing

# Verificar eventos
kubectl get events -n file-sharing --sort-by='.lastTimestamp'
```

### **3. Health Checks**

```bash
# Verificar readiness
kubectl get pods -n file-sharing -o wide

# Verificar liveness
kubectl describe pod -n file-sharing <pod-name>

# Verificar endpoints
kubectl get endpoints -n file-sharing
```

## 🔄 Rollback e Recuperação

### **1. Rollback Automático**

```bash
# Listar histórico de deploys
argocd app history file-sharing-app

# Rollback para versão anterior
argocd app rollback file-sharing-app 1

# Rollback para commit específico
argocd app rollback file-sharing-app --revision <commit-hash>
```

### **2. Rollback Manual**

```bash
# Pausar sync automático
argocd app set file-sharing-app --sync-policy-opt automated.prune=false

# Aplicar versão anterior
kubectl rollout undo deployment/frontend -n file-sharing
kubectl rollout undo deployment/backend -n file-sharing

# Verificar rollback
kubectl rollout status deployment/frontend -n file-sharing
kubectl rollout status deployment/backend -n file-sharing
```

### **3. Recuperação de Emergência**

```bash
# Deletar aplicação problemática
argocd app delete file-sharing-app --cascade

# Recriar aplicação
kubectl apply -f argocd/application.yaml

# Forçar sync
argocd app sync file-sharing-app --force
```

## 🔧 Configurações Avançadas

### **1. Blue-Green Deployment**

```yaml
# Configuração para blue-green
spec:
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
    automated:
      prune: false
      selfHeal: true
```

### **2. Canary Deployment**

```yaml
# Configuração para canary
spec:
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
    automated:
      prune: false
      selfHeal: true
```

### **3. Multi-Environment**

```yaml
# Configuração para múltiplos ambientes
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: file-sharing-dev
spec:
  source:
    path: helm
    helm:
      values: |
        global:
          environment: development
        frontend:
          replicaCount: 1
        backend:
          replicaCount: 1
        storage:
          persistentVolume:
            enabled: false  # Demo sem persistência
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: file-sharing-prod
spec:
  source:
    path: helm
    helm:
      values: |
        global:
          environment: production
        frontend:
          replicaCount: 3
        backend:
          replicaCount: 3
        storage:
          persistentVolume:
            enabled: true
            size: "100Gi"
            storageClass: "fast-ssd"
```

## 📈 Métricas e Observabilidade

### **1. Métricas do ArgoCD**

```bash
# Verificar métricas do ArgoCD
kubectl port-forward -n argocd svc/argocd-server-metrics 9092:9092

# Acessar Prometheus
curl http://localhost:9092/metrics
```

### **2. Logs Estruturados**

```yaml
# Configuração de logging
spec:
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
    automated:
      prune: true
      selfHeal: true
    # Configuração de logs
    logFormat: json
    logLevel: info
```

### **3. Alertas**

```yaml
# Configuração de alertas
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: argocd-alerts
  namespace: argocd
spec:
  route:
    receiver: 'slack'
    group_by: ['alertname']
    group_wait: 10s
    group_interval: 10s
    repeat_interval: 1h
  receivers:
    - name: 'slack'
      slackConfigs:
        - apiURL: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
          channel: '#alerts'
          title: 'ArgoCD Alert'
          text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

## 🛠️ Troubleshooting

### **Problemas Comuns**

#### **1. Sync Falha**

```bash
# Verificar logs do ArgoCD
kubectl logs -n argocd deployment/argocd-server

# Verificar status da aplicação
argocd app get file-sharing-app

# Verificar recursos
argocd app resources file-sharing-app
```

#### **2. Pods não iniciam**

```bash
# Verificar eventos
kubectl get events -n file-sharing --sort-by='.lastTimestamp'

# Verificar logs dos pods
kubectl logs -n file-sharing deployment/frontend
kubectl logs -n file-sharing deployment/backend

# Verificar configurações
kubectl describe pod -n file-sharing <pod-name>
```

#### **3. Ingress não funciona**

```bash
# Verificar ingress controller
kubectl get pods -n ingress-nginx

# Verificar ingress
kubectl describe ingress -n file-sharing

# Verificar certificados
kubectl get secrets -n file-sharing
```

### **Comandos de Debug**

```bash
# Debug completo da aplicação
argocd app get file-sharing-app --output yaml

# Verificar diferenças
argocd app diff file-sharing-app

# Forçar sync
argocd app sync file-sharing-app --force

# Verificar health
argocd app health file-sharing-app
```

## 🔒 Segurança do Deploy

### **1. RBAC para ArgoCD**

```yaml
# Configuração de RBAC
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-application-controller
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "endpoints", "persistentvolumeclaims", "events", "configmaps", "secrets"]
    verbs: ["get", "list", "watch", "patch", "update"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets", "statefulsets"]
    verbs: ["get", "list", "watch", "patch", "update"]
```

### **2. Network Policies**

```yaml
# Network policy para ArgoCD
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argocd-network-policy
  namespace: argocd
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: argocd-server
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 443
```

### **3. Secrets Management**

```bash
# Criar secret para ArgoCD
kubectl create secret generic argocd-secret \
  --from-literal=admin.password='$(openssl rand -base64 32)' \
  -n argocd

# Configurar external secrets
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: argocd-external-secret
  namespace: argocd
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: argocd-secret
  data:
    - secretKey: admin.password
      remoteRef:
        key: argocd/admin-password
EOF
```

## 📚 Referências

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Best Practices](https://www.gitops.tech/)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Helm Deployments](https://helm.sh/docs/intro/using_helm/)

---

**Próximo**: [Troubleshooting](TROUBLESHOOTING.md) - Procedimentos de Troubleshooting