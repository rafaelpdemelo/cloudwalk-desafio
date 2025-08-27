# 🔐 Scripts de Teste de Segurança - CloudWalk File Sharing

Este diretório contém **22 scripts automatizados** para testar a segurança da aplicação CloudWalk File Sharing de forma abrangente.

## 🚀 Execução Rápida

### Executar Todos os Testes
```bash
cd cloudwalk-app/scripts
bash run-all-security-tests.sh
```

### Executar Categoria Específica
```bash
# Rate Limiting
bash test-rate-limiting-global.sh
bash test-rate-limiting-upload.sh

# Autenticação
bash test-auth-no-password.sh
bash test-auth-wrong-password.sh

# Upload & Validação
bash test-file-size-limit.sh
bash test-file-type-validation.sh
```

## 📋 Testes Disponíveis por Categoria

### 🚦 Rate Limiting & Proteção DoS
| Script | Descrição | Objetivo |
|--------|-----------|----------|
| `test-rate-limiting-global.sh` | Limite global de requests | Verificar 100 req/15min |
| `test-rate-limiting-upload.sh` | Slow down em uploads | Verificar delay após 5º upload |
| `test-dos-protection.sh` | Proteção contra DoS | Testar conexões simultâneas |

### 🔒 Autenticação & Autorização
| Script | Descrição | Objetivo |
|--------|-----------|----------|
| `test-auth-no-password.sh` | Acesso sem senha | Verificar bloqueio |
| `test-auth-wrong-password.sh` | Senhas incorretas | Verificar rejeição |
| `test-auth-invalid-token.sh` | Tokens inválidos | Verificar validação |

### 📁 Upload & Validação de Arquivos
| Script | Descrição | Objetivo |
|--------|-----------|----------|
| `test-file-size-limit.sh` | Limite de tamanho (50MB) | Evitar DoS por arquivo grande |
| `test-file-type-validation.sh` | Tipos de arquivo maliciosos | Bloquear PHP, EXE, etc. |
| `test-magic-numbers.sh` | Validação de magic numbers | Detectar arquivos disfarçados |

### 🛡️ Injeção & XSS
| Script | Descrição | Objetivo |
|--------|-----------|----------|
| `test-sql-injection.sh` | SQL Injection | Verificar proteção |
| `test-xss-filename.sh` | XSS em nomes de arquivo | Verificar sanitização |
| `test-path-traversal.sh` | Path Traversal | Evitar acesso a arquivos do sistema |

### 🔐 Criptografia & Proteção de Dados
| Script | Descrição | Objetivo |
|--------|-----------|----------|
| `test-encryption-strength.sh` | Força da criptografia | Verificar AES-256 |
| `test-decryption-failure.sh` | Falhas na descriptografia | Tratar senhas incorretas |

### 🌐 Headers & Information Disclosure
| Script | Descrição | Objetivo |
|--------|-----------|----------|
| `test-security-headers.sh` | Headers de segurança | CSP, HSTS, X-Frame-Options |
| `test-information-disclosure.sh` | Vazamento de informações | Proteger arquivos sensíveis |

### ⏰ TTL & Expiração
| Script | Descrição | Objetivo |
|--------|-----------|----------|
| `test-ttl-validation.sh` | Validação de TTL | Valores válidos |
| `test-file-expiration.sh` | Expiração de arquivos | Limpeza automática |

### 🔄 CSRF & CORS
| Script | Descrição | Objetivo |
|--------|-----------|----------|
| `test-csrf-protection.sh` | Proteção CSRF | Evitar ataques cross-site |
| `test-cors-policy.sh` | Política CORS | Controlar origens |

### 📊 Logs & Auditoria
| Script | Descrição | Objetivo |
|--------|-----------|----------|
| `test-security-logs.sh` | Logs de segurança | Registrar eventos suspeitos |
| `test-audit-trail.sh` | Trilha de auditoria | Rastrear ações de usuários |

## 📊 Interpretação dos Resultados

### ✅ Teste Passou
- **Significado**: Proteção funcionando corretamente
- **Ação**: Nenhuma ação necessária

### ❌ Teste Falhou
- **Significado**: Possível vulnerabilidade detectada
- **Ação**: Investigar e corrigir

### ⚠️ Atenção
- **Significado**: Comportamento suspeito ou proteção parcial
- **Ação**: Revisar implementação

## 🔧 Pré-requisitos

### 1. Aplicação Rodando
```bash
cd cloudwalk-app
./setup.sh
```

### 2. Ferramentas Necessárias
- `curl` - Para requests HTTP
- `jq` - Para parsing JSON
- `kubectl` - Para acessar Kubernetes
- `bash` - Shell script executor

### 3. Verificar Conectividade
```bash
curl -k https://localhost:8443/health
```

## 📈 Métricas de Avaliação

| Taxa de Sucesso | Classificação | Ação Recomendada |
|-----------------|---------------|-------------------|
| 95-100% | 🎉 Excelente | Manter monitoramento |
| 85-94% | 👍 Muito Bom | Pequenos ajustes |
| 70-84% | ✅ Bom | Melhorias pontuais |
| 50-69% | ⚠️ Atenção | Revisão necessária |
| <50% | 🚨 Crítico | Correções urgentes |

## 📁 Arquivos Gerados

- `security_test_results.log` - Relatório completo
- `/tmp/test_*` - Arquivos temporários (auto-removidos)

## 🔍 Solução de Problemas

### Aplicação não responde
```bash
# Verificar status dos pods
kubectl get pods -n file-sharing

# Verificar logs
kubectl logs -n file-sharing deployment/file-sharing-backend

# Re-iniciar aplicação
cd cloudwalk-app && ./setup.sh
```

### Testes falhando inesperadamente
```bash
# Verificar conectividade
curl -k https://localhost:8443/health

# Verificar port-forward
kubectl port-forward -n file-sharing service/file-sharing-frontend 8443:3001 &
```

### Permissões negadas
```bash
chmod +x scripts/*.sh
```

## 🎯 Casos de Uso

### Para Desenvolvimento
```bash
# Testar apenas autenticação
bash test-auth-no-password.sh
bash test-auth-wrong-password.sh
```

### Para CI/CD
```bash
# Executar suite completa
bash run-all-security-tests.sh
exit_code=$?
if [ $exit_code -ne 0 ]; then
    echo "Security tests failed!"
    exit 1
fi
```

### Para Auditoria de Segurança
```bash
# Gerar relatório completo
bash run-all-security-tests.sh
cat security_test_results.log
```

## 🤝 Contribuindo

### Adicionar Novo Teste
1. Criar script seguindo padrão: `test-categoria-nome.sh`
2. Usar saída padronizada: `✅ PASSOU` ou `❌ FALHOU`
3. Adicionar na categoria apropriada em `run-all-security-tests.sh`
4. Documentar no README

### Padrão de Script
```bash
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Nome do Teste"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Descrever o que está sendo testado"

# ... lógica do teste ...

if [ condição_sucesso ]; then
    echo "✅ PASSOU: Descrição do sucesso"
    exit 0
else
    echo "❌ FALHOU: Descrição da falha"
    exit 1
fi
```
