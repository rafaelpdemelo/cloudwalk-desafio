# Troubleshooting - CloudWalk Desafio

## 📋 Visão Geral

Este documento fornece soluções para problemas comuns encontrados durante o desenvolvimento e deploy da aplicação File Sharing.

## 🚨 Problemas Críticos

### **1. Minikube não inicia**

**Sintomas:**
```bash
❌ minikube start --profile cloudwalk-desafio
```

**Soluções:**

```bash
# Limpar completamente
minikube delete --profile cloudwalk-desafio
minikube start --profile cloudwalk-desafio --driver=docker

# Verificar Docker
docker ps
docker system info

# Verificar recursos
minikube start --profile cloudwalk-desafio \
  --driver=docker \
  --cpus=2 \
  --memory=4096 \
  --disk-size=20g
```

### **2. ArgoCD não sincroniza**

**Sintomas:**
```bash
❌ argocd app sync file-sharing-app
```

**Soluções:**

```bash
# Verificar status
argocd app get file-sharing-app

# Forçar sync
argocd app sync file-sharing-app --force

# Verificar logs
kubectl logs -n argocd deployment/argocd-server

# Recriar aplicação
argocd app delete file-sharing-app --cascade
kubectl apply -f argocd/application.yaml
```

### **3. Aplicação não acessível**

**Sintomas:**
```bash
❌ curl http://localhost:8080/
```

**Soluções:**

```bash
# Verificar pods
kubectl get pods -n file-sharing

# Verificar services
kubectl get svc -n file-sharing

# Verificar ingress
kubectl get ingress -n file-sharing

# Configurar port-forward
make port-forward
```

## 🔧 Problemas de Configuração

### **1. Certificados inválidos**

```bash
# Regenerar certificados
make generate-certs

# Verificar certificados
openssl x509 -in scripts/certs/tls.crt -text -noout

# Aplicar certificados
kubectl apply -f scripts/certs/tls-secret.yaml
```

### **2. Network Policies bloqueando tráfego**

```bash
# Verificar Network Policies
kubectl get networkpolicies -n file-sharing

# Desabilitar temporariamente
kubectl delete networkpolicy --all -n file-sharing

# Recriar com configurações corretas
kubectl apply -f helm/templates/network-policy.yaml
```

### **3. Storage não disponível**

```bash
# Verificar PVC
kubectl get pvc -n file-sharing

# Verificar PV
kubectl get pv

# Verificar storage classes
kubectl get storageclass

# Recriar storage
kubectl delete pvc --all -n file-sharing
kubectl apply -f helm/templates/storage.yaml
```

### **4. Arquivos perdidos após restart**

**Problema:** Arquivos são perdidos quando o pod é reiniciado.

**Causa:** PVC desabilitado ou usando emptyDir.

**Soluções:**

```bash
# Verificar configuração atual
kubectl get pvc -n file-sharing

# Se não há PVC, habilitar:
# Editar values.yaml:
storage:
  persistentVolume:
    enabled: true
    size: "10Gi"

# Reaplicar configuração
helm upgrade file-sharing-app ./helm
```

**Para Demo (aceitar perda de dados):**
```yaml
# values-demo.yaml
storage:
  persistentVolume:
    enabled: false  # Usa emptyDir (temporário)
```

## 🐛 Problemas de Aplicação

### **1. Frontend não carrega**

```bash
# Verificar logs do frontend
kubectl logs -n file-sharing deployment/frontend

# Verificar configurações
kubectl describe pod -n file-sharing -l app=frontend

# Reiniciar deployment
kubectl rollout restart deployment/frontend -n file-sharing
```

### **2. Backend não responde**

```bash
# Verificar logs do backend
kubectl logs -n file-sharing deployment/backend

# Verificar health check
curl -f http://localhost:3000/health

# Verificar recursos
kubectl top pods -n file-sharing
```

### **3. Upload/Download falha**

```bash
# Verificar permissões de storage
kubectl exec -n file-sharing deployment/backend -- ls -la /app/uploads

# Verificar espaço em disco
kubectl exec -n file-sharing deployment/backend -- df -h

# Verificar logs de upload
kubectl logs -n file-sharing deployment/backend | grep -i "upload\|download"
```

## 📊 Problemas de Monitoramento

### **1. Logs não aparecem**

```bash
# Verificar se pods estão rodando
kubectl get pods -n file-sharing

# Verificar logs com timestamps
kubectl logs -n file-sharing deployment/backend --timestamps

# Verificar eventos
kubectl get events -n file-sharing --sort-by='.lastTimestamp'
```

### **2. Métricas não disponíveis**

```bash
# Verificar metrics-server
kubectl get pods -n kube-system | grep metrics-server

# Habilitar metrics-server
minikube addons enable metrics-server

# Verificar métricas
kubectl top pods -n file-sharing
```

## 🔒 Problemas de Segurança

### **1. Testes de segurança falham**

```bash
# Verificar ferramentas instaladas
which trivy
which nmap
which kube-bench

# Instalar ferramentas faltantes
brew install trivy nmap kube-bench

# Executar testes novamente
make test-sec
```

### **2. Vulnerabilidades críticas**

```bash
# Atualizar imagens
docker pull cloudwalk/file-sharing-frontend:latest
docker pull cloudwalk/file-sharing-backend:latest

# Rebuild e redeploy
make build-images
make deploy
```

## 🛠️ Comandos de Debug

### **Diagnóstico Completo**

```bash
#!/bin/bash
# debug-complete.sh

echo "🔍 Diagnóstico completo iniciado..."

echo "📊 Status do cluster:"
kubectl cluster-info

echo "📦 Status dos pods:"
kubectl get pods --all-namespaces

echo "🔗 Status dos serviços:"
kubectl get svc --all-namespaces

echo "🌐 Status do ingress:"
kubectl get ingress --all-namespaces

echo "💾 Status do storage:"
kubectl get pvc,pv --all-namespaces

echo "📋 Eventos recentes:"
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20

echo "✅ Diagnóstico concluído!"
```

### **Logs de Debug**

```bash
# Logs detalhados
kubectl logs -n file-sharing deployment/backend --previous
kubectl logs -n file-sharing deployment/frontend --previous

# Logs do sistema
kubectl logs -n kube-system deployment/coredns
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### **Informações para Suporte**

```bash
# Coletar informações do sistema
kubectl version
minikube version
docker version
helm version

# Coletar logs
kubectl logs -n file-sharing deployment/backend > backend-logs.txt
kubectl logs -n file-sharing deployment/frontend > frontend-logs.txt

# Coletar configurações
kubectl get all -n file-sharing -o yaml > app-config.yaml
```
---

**Voltar ao**: [README](../README.md) - Documentação principal
