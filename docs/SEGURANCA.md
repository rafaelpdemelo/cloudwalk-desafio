# Segurança - CloudWalk Desafio

## 📋 Visão Geral

Este documento descreve as políticas de segurança implementadas na aplicação File Sharing, incluindo configurações de TLS, Network Policies, RBAC e outras medidas de proteção.

## 🛡️ Camadas de Segurança

### **Defense in Depth**

```
┌─────────────────────────────────────────────────────────────┐
│                    Camada 1: Network                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │   Ingress       │  │   Network       │  │   Firewall  │  │
│  │   Security      │  │   Policies      │  │   Rules     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   Camada 2: Application                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │   TLS/SSL       │  │   Input         │  │   Session   │  │
│  │   Encryption    │  │   Validation    │  │   Security  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Camada 3: Container                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │   Security      │  │   Resource      │  │   Image     │  │
│  │   Context       │  │   Limits        │  │   Scanning  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Camada 4: Access                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │   RBAC          │  │   Service       │  │   Audit     │  │
│  │   Policies      │  │   Accounts      │  │   Logging   │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🔐 Configurações de TLS/SSL

### **Certificados Self-Signed**

```bash
# Geração de certificados
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=file-sharing.local/O=CloudWalk/C=BR"
```

### **Configuração do Ingress**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: file-sharing-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  tls:
    - hosts:
        - file-sharing.local
      secretName: file-sharing-tls
  rules:
    - host: file-sharing.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

### **Headers de Segurança HTTP**

```yaml
# Configurações no Ingress
annotations:
  nginx.ingress.kubernetes.io/configuration-snippet: |
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
```

## 🌐 Network Policies

### **Política para Frontend**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-network-policy
  namespace: file-sharing
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
    - Ingress
    - Egress
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
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: backend
      ports:
        - protocol: TCP
          port: 3000
    - to: []
      ports:
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
```

### **Política para Backend**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-network-policy
  namespace: file-sharing
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 3000
  egress:
    - to: []
      ports:
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
```

## 🔑 RBAC (Role-Based Access Control)

### **Service Account**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: file-sharing-sa
  namespace: file-sharing
  labels:
    app: file-sharing-app
```

### **Role**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: file-sharing-role
  namespace: file-sharing
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "endpoints"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

### **RoleBinding**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: file-sharing-rolebinding
  namespace: file-sharing
subjects:
  - kind: ServiceAccount
    name: file-sharing-sa
    namespace: file-sharing
roleRef:
  kind: Role
  name: file-sharing-role
  apiGroup: rbac.authorization.k8s.io
```

## 🐳 Container Security

### **Security Context**

```yaml
securityContext:
  # Não rodar como root
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  
  # Não permitir escalação de privilégios
  allowPrivilegeEscalation: false
  
  # Sistema de arquivos somente leitura (quando possível)
  readOnlyRootFilesystem: true
  
  # Remover todas as capabilities
  capabilities:
    drop:
      - ALL
```

### **Resource Limits**

```yaml
resources:
  limits:
    cpu: "500m"
    memory: "512Mi"
  requests:
    cpu: "100m"
    memory: "128Mi"
```

### **Pod Security Standards**

```yaml
# Pod Security Policy
apiVersion: policy/v1
kind: PodSecurityPolicy
metadata:
  name: file-sharing-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
      - min: 1
        max: 65535
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      - min: 1
        max: 65535
  readOnlyRootFilesystem: true
```

## 🔍 Input Validation e Sanitização

### **Frontend Validation**

```javascript
// Validação de arquivos
const validateFile = (file) => {
  const maxSize = 100 * 1024 * 1024; // 100MB
  const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];
  
  if (file.size > maxSize) {
    throw new Error('Arquivo muito grande');
  }
  
  if (!allowedTypes.includes(file.type)) {
    throw new Error('Tipo de arquivo não permitido');
  }
  
  return true;
};

// Sanitização de inputs
const sanitizeInput = (input) => {
  return input.replace(/[<>]/g, '');
};
```

### **Backend Validation**

```javascript
// Middleware de validação
const validateUpload = (req, res, next) => {
  const file = req.file;
  
  // Verificar tamanho
  if (file.size > 100 * 1024 * 1024) {
    return res.status(400).json({ error: 'Arquivo muito grande' });
  }
  
  // Verificar tipo MIME
  const allowedMimes = ['image/jpeg', 'image/png', 'application/pdf'];
  if (!allowedMimes.includes(file.mimetype)) {
    return res.status(400).json({ error: 'Tipo de arquivo não permitido' });
  }
  
  // Verificar extensão
  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];
  const ext = path.extname(file.originalname).toLowerCase();
  if (!allowedExtensions.includes(ext)) {
    return res.status(400).json({ error: 'Extensão não permitida' });
  }
  
  next();
};
```

## 🛡️ Proteção contra Ataques Comuns

### **1. Cross-Site Scripting (XSS)**

```javascript
// Headers de segurança
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  xssFilter: true,
  noSniff: true,
  frameguard: { action: 'sameorigin' }
}));
```

### **2. Cross-Site Request Forgery (CSRF)**

```javascript
// Middleware CSRF
app.use(csrf({ cookie: true }));

// Token CSRF em formulários
app.get('/upload', (req, res) => {
  res.render('upload', { csrfToken: req.csrfToken() });
});
```

### **3. SQL Injection**

```javascript
// Usar prepared statements
const getFile = async (fileId) => {
  const query = 'SELECT * FROM files WHERE id = ?';
  const [rows] = await db.execute(query, [fileId]);
  return rows[0];
};
```

### **4. Path Traversal**

```javascript
// Validação de caminhos
const validatePath = (filePath) => {
  const normalizedPath = path.normalize(filePath);
  const uploadDir = path.resolve('./uploads');
  
  if (!normalizedPath.startsWith(uploadDir)) {
    throw new Error('Caminho inválido');
  }
  
  return normalizedPath;
};
```
### **Comandos de Emergência**

```bash
# Isolar namespace
kubectl label namespace file-sharing security=quarantine

# Bloquear tráfego
kubectl delete networkpolicy --all -n file-sharing

# Rotacionar secrets
kubectl delete secret file-sharing-secrets -n file-sharing

# Verificar logs de segurança
kubectl logs -n file-sharing -l app=backend | grep -i "security\|error\|unauthorized"
```

## 📚 Referências

- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

**Próximo**: [Instalação](INSTALACAO.md) - Instruções de instalação em diferentes sistemas operacionais
