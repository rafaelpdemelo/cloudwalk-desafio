# 🛡️ Security Documentation

## 📋 Visão Geral de Segurança

Este documento detalha todas as medidas de segurança implementadas na aplicação de compartilhamento de arquivos, seguindo as melhores práticas da indústria e frameworks de segurança reconhecidos.

## 🎯 Frameworks de Segurança Seguidos

- **OWASP Top 10** - Proteção contra principais vulnerabilidades web
- **NIST Cybersecurity Framework** - Gestão abrangente de riscos
- **CIS Kubernetes Benchmark** - Hardening de containers e orquestração

## 🔐 Threat Model

### Assets Protegidos
1. **Arquivos do usuário** - Dados sensíveis uploadados
2. **Metadados** - Informações sobre arquivos e usuários
3. **Infraestrutura** - Cluster Kubernetes e componentes
4. **Aplicação** - Código fonte e configurações

### Threat Actors
- **Atacantes externos** - Hackers tentando acesso não autorizado
- **Usuários maliciosos** - Abuso das funcionalidades da aplicação

### Attack Vectors
- **Web Application** - Injeção, XSS, CSRF
- **Network** - MITM, DDoS, port scanning
- **Container** - Container escape, privilege escalation
- **Supply Chain** - Dependências maliciosas, images comprometidas

## 🛡️ Controles de Segurança Implementados

### 1. Application Security

#### 1.1 Input Validation & Sanitization

```javascript
// Joi schema validation
const uploadSchema = Joi.object({
  file: Joi.object().required(),
  password: Joi.string().min(8).max(128).required(),
  ttl: Joi.number().min(3600).max(86400).default(3600)
});

// File type validation
const allowedMimeTypes = [
  'application/pdf',
  'image/jpeg',
  'image/png',
  'text/plain',
  'application/zip'
];

// Filename sanitization
const sanitizeFilename = require('sanitize-filename');
const cleanFilename = sanitizeFilename(originalName);
```

#### 1.2 Encryption at Rest

```javascript
// AES-256-GCM encryption
const crypto = require('crypto');

function encryptFile(buffer, password) {
  const algorithm = 'aes-256-gcm';
  const key = crypto.scryptSync(password, 'salt', 32);
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipher(algorithm, key);
  
  const encrypted = Buffer.concat([
    cipher.update(buffer),
    cipher.final()
  ]);
  
  const authTag = cipher.getAuthTag();
  
  return {
    encrypted,
    iv: iv.toString('hex'),
    authTag: authTag.toString('hex')
  };
}
```

#### 1.3 Password Security

```javascript
const bcrypt = require('bcrypt');

// Hash password with salt + pepper
async function hashPassword(password) {
  const saltRounds = 12;
  const pepper = process.env.PASSWORD_PEPPER;
  const pepperedPassword = password + pepper;
  
  return await bcrypt.hash(pepperedPassword, saltRounds);
}

// Verify password
async function verifyPassword(password, hash) {
  const pepper = process.env.PASSWORD_PEPPER;
  const pepperedPassword = password + pepper;
  
  return await bcrypt.compare(pepperedPassword, hash);
}
```

#### 1.4 Rate Limiting & DDoS Protection

```javascript
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP',
  standardHeaders: true,
  legacyHeaders: false,
});

// Slow down repeated requests
const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000, // 15 minutes
  delayAfter: 50, // allow 50 requests per windowMs without delay
  delayMs: 500 // add 500ms delay per request after delayAfter
});
```

#### 1.5 Security Headers

```javascript
const helmet = require('helmet');

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  noSniff: true,
  xssFilter: true,
  referrerPolicy: { policy: "strict-origin-when-cross-origin" }
}));
```

### 2. Container Security

#### 2.1 Multi-stage Dockerfile

```dockerfile
# Frontend production build
FROM node:18-alpine AS frontend-build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Production image - minimal attack surface
FROM nginx:alpine
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup
COPY --from=frontend-build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
USER 1001
EXPOSE 80
```

#### 2.2 Security Context

```yaml
# Pod Security Context
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  runAsGroup: 1001
  fsGroup: 1001
  seccompProfile:
    type: RuntimeDefault

# Container Security Context
containers:
- name: app
  securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
      - ALL
    runAsNonRoot: true
    runAsUser: 1001
```

### 3. Kubernetes Security

#### 3.1 Pod Security Standards

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: file-sharing
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

#### 3.2 Network Policies

```yaml
# Default deny-all policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: file-sharing
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# Allow frontend to proxy communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-proxy
  namespace: file-sharing
spec:
  podSelector:
    matchLabels:
      app: proxy
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
```

#### 3.3 RBAC Configuration

```yaml
# ServiceAccount for application
apiVersion: v1
kind: ServiceAccount
metadata:
  name: file-sharing-sa
  namespace: file-sharing
automountServiceAccountToken: false

---
# Minimal ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: file-sharing-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

---
# ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: file-sharing-binding
subjects:
- kind: ServiceAccount
  name: file-sharing-sa
  namespace: file-sharing
roleRef:
  kind: ClusterRole
  name: file-sharing-role
  apiGroup: rbac.authorization.k8s.io
```

## 🚨 Security Monitoring & Alerting

### Security Events to Monitor

1. **Authentication Failures**
   - Failed password attempts
   - Rate limit violations
   - Suspicious user agents

2. **File Access Anomalies**
   - Multiple download attempts
   - Large file uploads
   - Suspicious file types

3. **Infrastructure Events**
   - Pod crashes
   - Resource exhaustion
   - Network policy violations

4. **Application Errors**
   - Encryption/decryption failures
   - Input validation errors
   - Unexpected exceptions

### Structured Audit Logging

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ 
      filename: '/var/log/app/audit.log',
      maxsize: 10485760, // 10MB
      maxFiles: 5
    })
  ]
});

// Security event logging
function logSecurityEvent(event, details) {
  logger.warn('Security Event', {
    event_type: event,
    timestamp: new Date().toISOString(),
    client_ip: details.ip,
    user_agent: details.userAgent,
    details: details,
    severity: 'HIGH'
  });
}
```

## 🔍 Security Testing

### Automated Security Tests

```javascript
// Jest security tests
describe('Security Tests', () => {
  test('should reject files larger than 50MB', async () => {
    const largeFile = Buffer.alloc(50 * 1024 * 1024 + 1);
    const response = await request(app)
      .post('/api/upload')
      .attach('file', largeFile, 'large.bin');
    
    expect(response.status).toBe(413);
  });

  test('should require strong passwords', async () => {
    const weakPasswords = ['123', 'password', 'abc'];
    
    for (const password of weakPasswords) {
      const response = await request(app)
        .post('/api/upload')
        .field('password', password);
      
      expect(response.status).toBe(400);
    }
  });

  test('should sanitize file names', async () => {
    const maliciousName = '../../../etc/passwd';
    const response = await request(app)
      .post('/api/upload')
      .attach('file', Buffer.from('test'), maliciousName);
    
    expect(response.body.filename).not.toContain('../');
  });
});
```

## 📊 Security Compliance

### Compliance Requirements Met

| Standard | Requirement | Implementation | Status |
|----------|-------------|----------------|--------|
| **OWASP** | Input validation | Joi schemas + sanitization | ✅ |
| **OWASP** | Authentication | Bcrypt + salt + pepper | ✅ |
| **OWASP** | Encryption | AES-256-GCM at rest | ✅ |
| **OWASP** | Access control | RBAC + principle of least privilege | ✅ |
| **OWASP** | Security logging | Structured JSON logs | ✅ |
| **CIS** | Container hardening | Non-root + read-only filesystem | ✅ |
| **CIS** | Network segmentation | Network policies + firewalls | ✅ |
| **CIS** | Secret management | Kubernetes secrets + encryption | ✅ |
| **NIST** | Risk assessment | Threat modeling completed | ✅ |
| **NIST** | Incident response | Monitoring + alerting configured | ✅ |

### Security Audit Trail

```json
{
  "timestamp": "2024-01-15T10:30:45.123Z",
  "event_type": "FILE_UPLOAD",
  "severity": "INFO",
  "user_ip": "192.168.1.100",
  "user_agent": "Mozilla/5.0...",
  "file_details": {
    "file_id": "550e8400-e29b-41d4-a716-446655440000",
    "original_name": "document.pdf",
    "sanitized_name": "document.pdf",
    "size_bytes": 2048000,
    "mime_type": "application/pdf",
    "encrypted": true
  },
  "security_checks": {
    "file_type_validation": "PASSED",
    "size_validation": "PASSED",
    "virus_scan": "PASSED",
    "malware_scan": "PASSED"
  },
  "correlation_id": "req-12345-upload"
}
```
