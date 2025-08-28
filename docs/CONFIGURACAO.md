# Configuração - CloudWalk Desafio

## 📋 Visão Geral

Este documento explica as configurações do Helm, variáveis de ambiente e como personalizar a aplicação File Sharing.

## 🎯 Por que Helm?

### **Vantagens do Helm**

1. **Templating Inteligente**
   - Reutilização de configurações
   - Variáveis dinâmicas
   - Condicionais e loops

2. **Versionamento**
   - Controle de versões das configurações
   - Rollback fácil
   - Histórico de mudanças

3. **Packaging**
   - Empacotamento completo da aplicação
   - Dependências gerenciadas
   - Distribuição simplificada

4. **Ecosystem**
   - Padrão da comunidade Kubernetes
   - Ferramentas de terceiros
   - Documentação rica

## 🏗️ Estrutura do Helm Chart

```
helm/
├── Chart.yaml              # Metadados do chart
├── values.yaml             # Valores padrão
├── templates/              # Templates Kubernetes
│   ├── _helpers.tpl        # Funções auxiliares
│   ├── namespace.yaml      # Namespace da aplicação
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── services.yaml       # Services
│   ├── ingress.yaml        # Ingress configuration
│   ├── storage.yaml        # PVC e Storage
│   └── network-policy.yaml # Network policies
└── charts/                 # Dependências (se houver)
```

## ⚙️ Configurações Principais

### **Chart.yaml**
```yaml
apiVersion: v2
name: file-sharing-app
description: Aplicação de compartilhamento de arquivos segura
type: application
version: 1.0.0
appVersion: "1.0.0"
keywords:
  - file-sharing
  - kubernetes
  - security
home: https://github.com/cloudwalk/file-sharing-app
sources:
  - https://github.com/cloudwalk/file-sharing-app
maintainers:
  - name: CloudWalk Team
    email: team@cloudwalk.work
```

### **values.yaml - Configurações Globais**
```yaml
# Configurações globais
global:
  environment: development
  domain: file-sharing.local
  
# Configurações da aplicação
app:
  name: file-sharing-app
  version: "1.0.0"
  
# Configurações de recursos
resources:
  cpu:
    request: "100m"
    limit: "500m"
  memory:
    request: "128Mi"
    limit: "512Mi"
    
# Configurações de storage
storage:
  size: "10Gi"
  accessMode: ReadWriteOnce
  storageClass: ""
```

## 🔧 Configurações por Componente

### **1. Frontend Configuration**

```yaml
frontend:
  enabled: true
  replicaCount: 1
  
  image:
    repository: cloudwalk/file-sharing-frontend
    tag: "1.0.0"
    pullPolicy: IfNotPresent
    
  service:
    type: ClusterIP
    port: 80
    targetPort: 3000
    
  ingress:
    enabled: true
    className: nginx
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    hosts:
      - host: file-sharing.local
        paths:
          - path: /
            pathType: Prefix
            
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
      
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
        - ALL
```

### **2. Backend Configuration**

```yaml
backend:
  enabled: true
  replicaCount: 1
  
  image:
    repository: cloudwalk/file-sharing-backend
    tag: "1.0.0"
    pullPolicy: IfNotPresent
    
  service:
    type: ClusterIP
    port: 3000
    targetPort: 3000
    
  env:
    NODE_ENV: production
    PORT: 3000
    UPLOAD_DIR: /app/uploads
    MAX_FILE_SIZE: "100MB"
    
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 200m
      memory: 256Mi
      
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: false  # Precisa escrever arquivos
    capabilities:
      drop:
        - ALL
```

### **3. Storage Configuration**

```yaml
storage:
  enabled: true
  
  persistentVolume:
    enabled: true          # Habilita PVC (recomendado para produção)
    size: "10Gi"
    accessMode: ReadWriteMany
    storageClass: ""       # Usa storage class padrão
    
  configMap:
    enabled: true
    data:
      app.config: |
        maxFileSize: 100MB
        allowedTypes: jpg,jpeg,png,pdf,doc,docx
        uploadPath: /app/uploads
        
  secrets:
    enabled: true
    data:
      api.key: base64-encoded-api-key
      db.password: base64-encoded-password
```

#### **⚠️ Configurações de Storage**

**Para Demo (Sem Persistência):**
```yaml
storage:
  persistentVolume:
    enabled: false  # Usa emptyDir (temporário)
```

**Para Produção (Com Persistência):**
```yaml
storage:
  persistentVolume:
    enabled: true
    size: "100Gi"
    storageClass: "fast-ssd"
    accessMode: ReadWriteMany
```

### **4. Security Configuration**

```yaml
security:
  networkPolicy:
    enabled: true
    ingress:
      - from:
          - namespaceSelector:
              matchLabels:
                name: ingress-nginx
        ports:
          - protocol: TCP
            port: 80
          - protocol: TCP
            port: 443
            
  rbac:
    enabled: true
    serviceAccount:
      create: true
      name: file-sharing-sa
      
  podSecurityPolicy:
    enabled: true
    privileged: false
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
```

## 🔐 Configurações de Segurança

### **Network Policies**

```yaml
networkPolicy:
  enabled: true
  
  # Política para frontend
  frontend:
    ingress:
      - from:
          - namespaceSelector:
              matchLabels:
                name: ingress-nginx
        ports:
          - protocol: TCP
            port: 80
    egress:
      - to:
          - podSelector:
              matchLabels:
                app: backend
        ports:
          - protocol: TCP
            port: 3000
            
  # Política para backend
  backend:
    ingress:
      - from:
          - podSelector:
              matchLabels:
                app: frontend
        ports:
          - protocol: TCP
            port: 3000
    egress:
      - to: []  # Sem egress por padrão
```

### **RBAC Configuration**

```yaml
rbac:
  enabled: true
  
  serviceAccount:
    create: true
    name: file-sharing-sa
    annotations: {}
    
  role:
    create: true
    rules:
      - apiGroups: [""]
        resources: ["pods", "services"]
        verbs: ["get", "list", "watch"]
      - apiGroups: [""]
        resources: ["configmaps", "secrets"]
        verbs: ["get"]
        
  roleBinding:
    create: true
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: file-sharing-role
    subjects:
      - kind: ServiceAccount
        name: file-sharing-sa
        namespace: file-sharing
```

## 🌍 Configurações por Ambiente

### **Development (values-dev.yaml)**

```yaml
global:
  environment: development
  
frontend:
  replicaCount: 1
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 50m
      memory: 64Mi
      
backend:
  replicaCount: 1
  env:
    NODE_ENV: development
    DEBUG: "true"
    
storage:
  persistentVolumeClaim:
    size: "5Gi"
```

### **Production (values-prod.yaml)**

```yaml
global:
  environment: production
  
frontend:
  replicaCount: 3
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 200m
      memory: 256Mi
      
backend:
  replicaCount: 3
  env:
    NODE_ENV: production
    DEBUG: "false"
    
storage:
  persistentVolumeClaim:
    size: "100Gi"
    storageClass: "fast-ssd"
```

## 💾 Storage e Persistência de Dados

### **Configuração Atual**

O projeto está configurado para usar **Persistent Volume Claims (PVC)** por padrão, o que significa que:

- ✅ **Arquivos são persistidos** entre restarts de pods
- ✅ **Dados sobrevivem** a reinicializações do cluster
- ✅ **Funciona com múltiplas réplicas** (ReadWriteMany)
- ✅ **Configurável** via Helm values

### **Para Demo Simples (Sem Persistência)**

Se você quiser uma configuração mais simples para demo, pode desabilitar o PVC:

```yaml
# values-demo.yaml
storage:
  persistentVolume:
    enabled: false  # Usa emptyDir (temporário)
```

**⚠️ Implicações do emptyDir:**
- ❌ **Arquivos são perdidos** quando o pod é reiniciado
- ❌ **Não funciona** com múltiplas réplicas
- ❌ **Dados não sobrevivem** a reinicializações do cluster
- ✅ **Setup mais simples** para demonstrações

### **Para Produção (Recomendado)**

```yaml
# values-prod.yaml
storage:
  persistentVolume:
    enabled: true
    size: "100Gi"
    storageClass: "fast-ssd"  # Storage class de alta performance
    accessMode: ReadWriteMany  # Múltiplas réplicas podem acessar
```

### **Storage Classes Disponíveis**

```bash
# Verificar storage classes disponíveis
kubectl get storageclass

# Exemplos de storage classes comuns:
# - standard (HDD)
# - fast-ssd (SSD)
# - premium-ssd (SSD de alta performance)
```

## 🔧 Personalização Avançada

### **1. Custom Values**

Crie um arquivo `my-values.yaml`:

```yaml
# my-values.yaml
frontend:
  replicaCount: 2
  image:
    tag: "latest"
    
backend:
  env:
    MAX_FILE_SIZE: "500MB"
    
storage:
  persistentVolumeClaim:
    size: "50Gi"
```

Aplique com:
```bash
helm install file-sharing-app ./helm -f my-values.yaml
```

### **2. Override de Configurações**

```bash
# Override via linha de comando
helm install file-sharing-app ./helm \
  --set frontend.replicaCount=3 \
  --set backend.env.MAX_FILE_SIZE=1GB \
  --set storage.persistentVolumeClaim.size=100Gi
```

### **3. Configurações Condicionais**

```yaml
# No template
{{- if .Values.security.networkPolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "file-sharing-app.fullname" . }}
spec:
  # ... configurações
{{- end }}
```

## 📊 Monitoramento e Logging

### **Configurações de Logging**

```yaml
logging:
  enabled: true
  level: info
  format: json
  
  frontend:
    level: warn
    format: text
    
  backend:
    level: info
    format: json
    file: /var/log/app.log
```

### **Configurações de Métricas**

```yaml
metrics:
  enabled: true
  
  frontend:
    enabled: true
    port: 9090
    path: /metrics
    
  backend:
    enabled: true
    port: 9090
    path: /metrics
```

## 🔄 Configurações de Deploy

### **Rolling Update Strategy**

```yaml
deployment:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
      
  # Health checks
  livenessProbe:
    httpGet:
      path: /health
      port: 3000
    initialDelaySeconds: 30
    periodSeconds: 10
    
  readinessProbe:
    httpGet:
      path: /ready
      port: 3000
    initialDelaySeconds: 5
    periodSeconds: 5
```

### **Configurações de HPA**

```yaml
autoscaling:
  enabled: true
  
  horizontalPodAutoscaler:
    minReplicas: 1
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

## 🛠️ Troubleshooting de Configurações

### **Problemas Comuns**

1. **Configurações não aplicadas**
   ```bash
   # Verificar valores aplicados
   helm get values file-sharing-app
   
   # Verificar templates gerados
   helm template file-sharing-app ./helm
   ```

2. **Erros de validação**
   ```bash
   # Validar templates
   helm lint ./helm
   
   # Dry-run para testar
   helm install file-sharing-app ./helm --dry-run
   ```

3. **Configurações de recursos**
   ```bash
   # Verificar uso de recursos
   kubectl top pods -n file-sharing
   
   # Ajustar limites
   helm upgrade file-sharing-app ./helm \
     --set frontend.resources.limits.memory=1Gi
   ```

## 📚 Referências

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Configuration](https://kubernetes.io/docs/concepts/configuration/)
- [Best Practices](https://helm.sh/docs/chart_best_practices/)

---

**Próximo**: [Segurança](SEGURANCA.md) - Políticas de segurança implementadas
