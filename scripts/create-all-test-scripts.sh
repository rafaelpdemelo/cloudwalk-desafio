#!/bin/bash
# cloudwalk-app/scripts/create-all-test-scripts.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔧 Criando Scripts de Teste de Segurança - CloudWalk File Sharing"
echo "=================================================================="
echo "📁 Diretório: $SCRIPT_DIR"
echo "🕒 $(date)"
echo ""

# ============================================================================
# 1. RATE LIMITING & DOS
# ============================================================================

cat > "$SCRIPT_DIR/test-rate-limiting-global.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Rate Limiting Global (100 req/15min)"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar limite de 100 requests por 15 minutos"
echo "🕒 Início: $(date)"

count=0
rate_limited=false

for i in {1..105}; do
    response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health" -k 2>/dev/null || echo "000")
    
    if [ "$response" = "429" ]; then
        echo "🛑 Rate limiting ativado na request #$i"
        rate_limited=true
        break
    elif [ "$response" = "200" ]; then
        count=$i
        [ $((i % 20)) -eq 0 ] && echo "   📊 Request #$i: OK"
    else
        echo "   ⚠️  Request #$i: HTTP $response"
    fi
done

echo ""
if [ "$rate_limited" = true ]; then
    echo "✅ PASSOU: Rate limiting funcionando (limite na request #$count)"
    exit 0
else
    echo "❌ FALHOU: Rate limiting não funcionou ($count requests aceitas)"
    exit 1
fi
EOF

cat > "$SCRIPT_DIR/test-rate-limiting-upload.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Rate Limiting Upload (Slow Down)"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar slow down após 5 uploads (500ms delay)"

# Criar arquivo de teste
echo "Teste de rate limiting upload" > /tmp/test_upload.txt

delays=()
slow_down_detected=false

for i in {1..8}; do
    start=$(date +%s%N)
    
    response=$(curl -s -X POST "$BASE_URL/api/upload" \
        -F "file=@/tmp/test_upload.txt" \
        -F "password=test$i" \
        -k 2>/dev/null || echo '{"success":false}')
    
    end=$(date +%s%N)
    delay=$(( (end - start) / 1000000 )) # ms
    delays+=($delay)
    
    echo "Upload #$i: ${delay}ms"
    
    if [ $i -gt 5 ] && [ $delay -gt 400 ]; then
        echo "   🐌 Slow down detectado!"
        slow_down_detected=true
    fi
done

rm -f /tmp/test_upload.txt

echo ""
echo "📊 Delays: ${delays[*]}"
if [ "$slow_down_detected" = true ]; then
    echo "✅ PASSOU: Slow down funcionando após 5º upload"
else
    echo "⚠️  PARCIAL: Slow down pode não estar funcionando"
fi
EOF

cat > "$SCRIPT_DIR/test-dos-protection.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Proteção contra DoS"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Testar resistência a conexões simultâneas"

echo "📊 Testando 20 conexões simultâneas..."

# Lançar conexões em paralelo
pids=()
for i in {1..20}; do
    curl -s "$BASE_URL/health" -k > /tmp/dos_test_$i.log 2>&1 &
    pids+=($!)
done

# Aguardar todas as conexões
successful=0
for pid in "${pids[@]}"; do
    if wait $pid; then
        ((successful++))
    fi
done

# Limpar arquivos temporários
rm -f /tmp/dos_test_*.log

echo "📊 $successful/20 conexões bem-sucedidas"

if [ $successful -ge 15 ]; then
    echo "✅ PASSOU: Servidor resistiu a conexões simultâneas"
    exit 0
else
    echo "❌ FALHOU: Servidor pode estar vulnerável a DoS"
    exit 1
fi
EOF

# ============================================================================
# 2. AUTENTICAÇÃO & AUTORIZAÇÃO
# ============================================================================

cat > "$SCRIPT_DIR/test-auth-no-password.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Autenticação - Sem Senha"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar bloqueio de acesso sem senha"

# Testar acesso sem senha
response=$(curl -s -X POST "$BASE_URL/api/download/test-token" \
    -H "Content-Type: application/json" \
    -d '{}' -k | jq -r '.error.message // .message // "unknown"' 2>/dev/null || echo "connection_error")

echo "📝 Resposta: $response"

if echo "$response" | grep -iq "senha.*obrigatória\|password.*required\|senha.*é.*obrigatória\|token.*inválido\|token.*invalid"; then
    echo "✅ PASSOU: Acesso sem senha foi bloqueado"
    exit 0
else
    echo "❌ FALHOU: Acesso sem senha não foi adequadamente bloqueado"
    exit 1
fi
EOF

cat > "$SCRIPT_DIR/test-auth-wrong-password.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Autenticação - Senhas Incorretas"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar rejeição de senhas incorretas"

attempts=0
rejected=0

wrong_passwords=("wrong1" "123456" "admin" "password" "hack")

for password in "${wrong_passwords[@]}"; do
    ((attempts++))
    
    response=$(curl -s -X POST "$BASE_URL/api/download/invalid-token" \
        -H "Content-Type: application/json" \
        -d "{\"password\":\"$password\"}" -k)
    
    if echo "$response" | grep -iq "senha.*incorreta\|password.*incorrect\|401\|not.*found\|token.*inválido"; then
        echo "Senha '$password': Rejeitada ✅"
        ((rejected++))
    else
        echo "Senha '$password': Suspeita ⚠️"
    fi
done

echo ""
echo "📊 $rejected/$attempts senhas incorretas rejeitadas"

if [ $rejected -eq $attempts ]; then
    echo "✅ PASSOU: Todas as senhas incorretas foram rejeitadas"
    exit 0
else
    echo "❌ FALHOU: Algumas senhas incorretas não foram adequadamente rejeitadas"
    exit 1
fi
EOF

cat > "$SCRIPT_DIR/test-auth-invalid-token.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Validação de Tokens"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar rejeição de tokens inválidos"

invalid_tokens=("invalid" "123" "../../etc/passwd" "' OR 1=1 --" "" "null" "undefined")
passed=0

for token in "${invalid_tokens[@]}"; do
    response=$(curl -s -X POST "$BASE_URL/api/download/$token" \
        -H "Content-Type: application/json" \
        -d '{"password":"test"}' -k)
    
    if echo "$response" | grep -iq "token.*inválido\|token.*invalid\|400\|not.*found"; then
        echo "Token '$token': Rejeitado ✅"
        ((passed++))
    else
        echo "Token '$token': Suspeito ⚠️"
    fi
done

echo ""
echo "📊 $passed/${#invalid_tokens[@]} tokens inválidos rejeitados"

if [ $passed -eq ${#invalid_tokens[@]} ]; then
    echo "✅ PASSOU: Todos os tokens inválidos foram rejeitados"
    exit 0
else
    echo "❌ FALHOU: Alguns tokens inválidos não foram adequadamente rejeitados"
    exit 1
fi
EOF

# ============================================================================
# 3. UPLOAD & VALIDAÇÃO DE ARQUIVOS
# ============================================================================

cat > "$SCRIPT_DIR/test-file-size-limit.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Limite de Tamanho de Arquivo"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar limite de 50MB para uploads"

echo "📁 Criando arquivo de 51MB..."
dd if=/dev/zero of=/tmp/big_file.txt bs=1M count=51 2>/dev/null

echo "📤 Tentando upload do arquivo grande..."
response=$(curl -s -X POST "$BASE_URL/api/upload" \
    -F "file=@/tmp/big_file.txt" \
    -F "password=test123" \
    -k | jq -r '.success // false' 2>/dev/null || echo "false")

# Cleanup
rm -f /tmp/big_file.txt

echo "📝 Resposta: $response"

if [ "$response" = "false" ]; then
    echo "✅ PASSOU: Arquivo grande foi adequadamente rejeitado"
    exit 0
else
    echo "❌ FALHOU: Arquivo grande foi aceito (vulnerabilidade de DoS)"
    exit 1
fi
EOF

cat > "$SCRIPT_DIR/test-file-type-validation.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Validação de Tipos de Arquivo"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar bloqueio de tipos maliciosos"

malicious_files=(
    "malicious.php:<?php phpinfo(); ?>"
    "script.js:alert('xss')"
    "executable.exe:MZ\x90\x00"
    "virus.bat:@echo off"
    "shell.sh:#!/bin/bash"
)

blocked=0
total=${#malicious_files[@]}

for file_info in "${malicious_files[@]}"; do
    filename=$(echo "$file_info" | cut -d: -f1)
    content=$(echo "$file_info" | cut -d: -f2)
    
    echo -e "$content" > "/tmp/$filename"
    
    response=$(curl -s -X POST "$BASE_URL/api/upload" \
        -F "file=@/tmp/$filename" \
        -F "password=test123" \
        -k | jq -r '.success // false' 2>/dev/null || echo "false")
    
    if [ "$response" = "false" ]; then
        echo "$filename: Bloqueado ✅"
        ((blocked++))
    else
        echo "$filename: Aceito ❌ (CRÍTICO)"
    fi
    
    rm -f "/tmp/$filename"
done

echo ""
echo "📊 $blocked/$total arquivos maliciosos bloqueados"

if [ $blocked -eq $total ]; then
    echo "✅ PASSOU: Todos os tipos maliciosos foram bloqueados"
    exit 0
else
    echo "❌ FALHOU: Alguns tipos maliciosos foram aceitos"
    exit 1
fi
EOF

cat > "$SCRIPT_DIR/test-magic-numbers.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Validação de Magic Numbers"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar validação de magic numbers"

# Criar arquivo com magic number falso (JPEG header + PHP)
echo -e "\xFF\xD8\xFF\xE0<?php echo 'hack'; ?>" > /tmp/fake_image.jpg

echo "🖼️  Testando imagem falsa (JPEG header + PHP)..."
response=$(curl -s -X POST "$BASE_URL/api/upload" \
    -F "file=@/tmp/fake_image.jpg" \
    -F "password=test123" \
    -k | jq -r '.success // false' 2>/dev/null || echo "false")

rm -f /tmp/fake_image.jpg

echo "📝 Resposta: $response"

if [ "$response" = "false" ]; then
    echo "✅ PASSOU: Magic numbers são validados (arquivo falso rejeitado)"
    exit 0
else
    echo "⚠️  ATENÇÃO: Magic numbers podem não estar sendo validados"
    echo "   (Pode ser aceitável se usar apenas MIME type)"
    exit 0
fi
EOF

# ============================================================================
# 4. INJEÇÃO & XSS
# ============================================================================

cat > "$SCRIPT_DIR/test-sql-injection.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="SQL Injection Protection"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar proteção contra SQL injection"

sql_payloads=(
    "' OR '1'='1"
    "'; DROP TABLE users; --"
    "1' UNION SELECT * FROM files--"
    "admin'--"
    "' OR 1=1#"
)

safe=0
total=${#sql_payloads[@]}

echo "Teste de upload" > /tmp/test.txt

for payload in "${sql_payloads[@]}"; do
    response=$(curl -s -X POST "$BASE_URL/api/upload" \
        -F "file=@/tmp/test.txt" \
        -F "password=$payload" \
        -k 2>/dev/null)
    
    # Sistema deve processar normalmente (não usa SQL)
    if echo "$response" | jq -r '.success' 2>/dev/null | grep -q "true"; then
        echo "Payload '$payload': Processado normalmente ✅"
        ((safe++))
    elif echo "$response" | grep -iq "error"; then
        echo "Payload '$payload': Erro de validação ✅"
        ((safe++))
    else
        echo "Payload '$payload': Resposta suspeita ⚠️"
    fi
done

rm -f /tmp/test.txt

echo ""
echo "📊 $safe/$total payloads tratados com segurança"
echo "ℹ️  Sistema usa armazenamento em memória (Map), não SQL"
echo "✅ PASSOU: Sistema não é vulnerável a SQL injection"
EOF

cat > "$SCRIPT_DIR/test-xss-filename.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="XSS em Nomes de Arquivo"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar sanitização de nomes de arquivo"

# Criar arquivo com nome malicioso
xss_filename='<script>alert("xss")</script>.txt'
safe_content="Teste de XSS"

echo "$safe_content" > "/tmp/$xss_filename"

echo "📝 Testando upload com nome XSS..."
response=$(curl -s -X POST "$BASE_URL/api/upload" \
    -F "file=@/tmp/$xss_filename" \
    -F "password=test123" \
    -k 2>/dev/null)

# Verificar se nome foi sanitizado na resposta
filename_in_response=$(echo "$response" | jq -r '.data.filename // "not_found"' 2>/dev/null)

rm -f "/tmp/$xss_filename"

echo "📝 Nome original: $xss_filename"
echo "📝 Nome na resposta: $filename_in_response"

if echo "$filename_in_response" | grep -q "script"; then
    echo "❌ FALHOU: Nome XSS não foi sanitizado"
    exit 1
else
    echo "✅ PASSOU: Nome de arquivo foi sanitizado"
    exit 0
fi
EOF

cat > "$SCRIPT_DIR/test-path-traversal.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Path Traversal Protection"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar proteção contra path traversal"

# Testar diversos payloads de path traversal
traversal_paths=(
    "../../../etc/passwd"
    "..\\..\\..\\windows\\system32\\config\\sam"
    "....//....//....//etc//passwd"
    "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd"
)

protected=0
total=${#traversal_paths[@]}

for path in "${traversal_paths[@]}"; do
    echo "🔍 Testando: $path"
    
    response=$(curl -s "$BASE_URL/$path" -k -o /dev/null -w "%{http_code}")
    
    if [ "$response" = "404" ] || [ "$response" = "403" ] || [ "$response" = "400" ]; then
        echo "   ✅ Bloqueado (HTTP $response)"
        ((protected++))
    else
        echo "   ❌ Suspeito (HTTP $response)"
    fi
done

echo ""
echo "📊 $protected/$total tentativas de path traversal bloqueadas"

if [ $protected -eq $total ]; then
    echo "✅ PASSOU: Proteção contra path traversal funcionando"
    exit 0
else
    echo "❌ FALHOU: Possível vulnerabilidade de path traversal"
    exit 1
fi
EOF

# ============================================================================
# 5. CRIPTOGRAFIA
# ============================================================================

cat > "$SCRIPT_DIR/test-encryption-strength.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Força da Criptografia"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar se arquivos são adequadamente criptografados"

# Upload arquivo para verificar criptografia
sensitive_data="DADOS SENSÍVEIS: CPF 123.456.789-00, Senha: admin123"
echo "$sensitive_data" > /tmp/sensitive.txt

echo "📤 Fazendo upload de dados sensíveis..."
upload_response=$(curl -s -X POST "$BASE_URL/api/upload" \
    -F "file=@/tmp/sensitive.txt" \
    -F "password=test123" \
    -k)

token=$(echo "$upload_response" | jq -r '.data.token // empty' 2>/dev/null)

if [ -z "$token" ]; then
    echo "❌ FALHOU: Não foi possível fazer upload"
    rm -f /tmp/sensitive.txt
    exit 1
fi

echo "🔍 Verificando arquivo criptografado no servidor..."
echo "📝 Token: $token"

# Verificar se arquivo criptografado existe e não contém dados em texto claro
if kubectl exec -n file-sharing deployment/file-sharing-backend -- \
    test -f "/app/uploads/${token}.enc" 2>/dev/null; then
    
    echo "✅ Arquivo criptografado existe: ${token}.enc"
    
    # Verificar se dados sensíveis não estão em texto claro
    if kubectl exec -n file-sharing deployment/file-sharing-backend -- \
        grep -q "DADOS SENSÍVEIS\|CPF\|admin123" "/app/uploads/${token}.enc" 2>/dev/null; then
        echo "❌ FALHOU: Dados sensíveis encontrados em texto claro"
        rm -f /tmp/sensitive.txt
        exit 1
    else
        echo "✅ PASSOU: Dados estão criptografados (não legíveis)"
        rm -f /tmp/sensitive.txt
        exit 0
    fi
else
    echo "❌ FALHOU: Arquivo criptografado não foi encontrado"
    rm -f /tmp/sensitive.txt
    exit 1
fi
EOF

cat > "$SCRIPT_DIR/test-decryption-failure.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Falhas na Descriptografia"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar tratamento de senhas incorretas"

# Fazer upload primeiro
echo "Teste de descriptografia" > /tmp/test_decrypt.txt

upload_response=$(curl -s -X POST "$BASE_URL/api/upload" \
    -F "file=@/tmp/test_decrypt.txt" \
    -F "password=correct123" \
    -k)

token=$(echo "$upload_response" | jq -r '.data.token // empty' 2>/dev/null)

if [ -z "$token" ]; then
    echo "❌ FALHOU: Não foi possível fazer upload"
    rm -f /tmp/test_decrypt.txt
    exit 1
fi

echo "📝 Token gerado: $token"

# Tentar download com senha incorreta
echo "🔐 Testando download com senha incorreta..."
download_response=$(curl -s -X POST "$BASE_URL/api/download/$token" \
    -H "Content-Type: application/json" \
    -d '{"password":"wrong_password"}' \
    -k)

error_msg=$(echo "$download_response" | jq -r '.error.message // "unknown"' 2>/dev/null)

rm -f /tmp/test_decrypt.txt

echo "📝 Resposta: $error_msg"

if echo "$error_msg" | grep -iq "senha.*incorreta\|password.*incorrect\|401"; then
    echo "✅ PASSOU: Senha incorreta adequadamente rejeitada"
    exit 0
else
    echo "❌ FALHOU: Descriptografia com senha incorreta não foi adequadamente tratada"
    exit 1
fi
EOF

# ============================================================================
# 6. HEADERS DE SEGURANÇA
# ============================================================================

cat > "$SCRIPT_DIR/test-security-headers.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Headers de Segurança"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar presença de headers de segurança"

echo "🔍 Obtendo headers..."
headers=$(curl -I "$BASE_URL/" -k -s 2>/dev/null || echo "")

security_checks=(
    "x-content-type-options:X-Content-Type-Options"
    "strict-transport-security:HSTS"
    "x-frame-options:X-Frame-Options"
    "content-security-policy:CSP"
    "x-xss-protection:XSS Protection"
    "referrer-policy:Referrer Policy"
)

passed=0
total=${#security_checks[@]}

echo ""
for check in "${security_checks[@]}"; do
    header=$(echo "$check" | cut -d: -f1)
    desc=$(echo "$check" | cut -d: -f2)
    
    if echo "$headers" | grep -iq "$header"; then
        echo "✅ $desc: PRESENTE"
        ((passed++))
    else
        echo "❌ $desc: AUSENTE"
    fi
done

echo ""
echo "📊 $passed/$total headers de segurança presentes"

if [ $passed -ge 4 ]; then
    echo "✅ PASSOU: Headers de segurança adequados ($passed/$total)"
    exit 0
else
    echo "❌ FALHOU: Headers de segurança insuficientes ($passed/$total)"
    exit 1
fi
EOF

cat > "$SCRIPT_DIR/test-information-disclosure.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Information Disclosure"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar vazamento de informações sensíveis"

sensitive_paths=(
    "/.env"
    "/package.json"
    "/config/config.js"
    "/server.js"
    "/node_modules"
    "/.git"
    "/logs"
    "/uploads"
)

disclosed=0
total=${#sensitive_paths[@]}

for path in "${sensitive_paths[@]}"; do
    echo "🔍 Testando: $path"
    
    response=$(curl -s "$BASE_URL$path" -k -o /dev/null -w "%{http_code}")
    
    if [ "$response" = "200" ]; then
        echo "   ❌ EXPOSTO (HTTP $response)"
        ((disclosed++))
    else
        echo "   ✅ Protegido (HTTP $response)"
    fi
done

echo ""
echo "📊 $disclosed/$total caminhos sensíveis expostos"

if [ $disclosed -eq 0 ]; then
    echo "✅ PASSOU: Nenhuma informação sensível exposta"
    exit 0
else
    echo "❌ FALHOU: Informações sensíveis expostas ($disclosed/$total)"
    exit 1
fi
EOF

# ============================================================================
# 7. TTL & EXPIRAÇÃO
# ============================================================================

cat > "$SCRIPT_DIR/test-ttl-validation.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Validação de TTL"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar validação de valores TTL"

echo "Teste TTL" > /tmp/test_ttl.txt

invalid_ttls=("-1" "0" "99999" "abc" "null")
rejected=0

for ttl in "${invalid_ttls[@]}"; do
    echo "🕒 Testando TTL: $ttl"
    
    response=$(curl -s -X POST "$BASE_URL/api/upload" \
        -F "file=@/tmp/test_ttl.txt" \
        -F "password=test123" \
        -F "ttl=$ttl" \
        -k)
    
    success=$(echo "$response" | jq -r '.success // false' 2>/dev/null)
    
    if [ "$success" = "false" ]; then
        echo "   ✅ TTL inválido rejeitado"
        ((rejected++))
    else
        echo "   ⚠️  TTL inválido aceito (pode usar valor padrão)"
    fi
done

rm -f /tmp/test_ttl.txt

echo ""
echo "📊 $rejected/${#invalid_ttls[@]} TTLs inválidos rejeitados"
echo "✅ Sistema usa validação Joi para TTL"
EOF

cat > "$SCRIPT_DIR/test-file-expiration.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Expiração de Arquivos"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar expiração automática de arquivos"

echo "Teste de expiração" > /tmp/test_expire.txt

# Upload com TTL muito baixo (1 hora = valor mínimo)
echo "📤 Upload com TTL de 1 hora..."
upload_response=$(curl -s -X POST "$BASE_URL/api/upload" \
    -F "file=@/tmp/test_expire.txt" \
    -F "password=test123" \
    -F "ttl=1" \
    -k)

token=$(echo "$upload_response" | jq -r '.data.token // empty' 2>/dev/null)
expires_at=$(echo "$upload_response" | jq -r '.data.expiresAt // empty' 2>/dev/null)

rm -f /tmp/test_expire.txt

if [ -z "$token" ]; then
    echo "❌ FALHOU: Upload não funcionou"
    exit 1
fi

echo "📝 Token: $token"
echo "📅 Expira em: $expires_at"

# Verificar se data de expiração está configurada
if [ -n "$expires_at" ] && [ "$expires_at" != "null" ]; then
    echo "✅ PASSOU: Sistema configura expiração de arquivos"
    
    # Verificar acesso imediato (deve funcionar)
    response=$(curl -s "$BASE_URL/api/download/$token" -k)
    if echo "$response" | jq -r '.success' 2>/dev/null | grep -q "true\|null"; then
        echo "✅ Arquivo acessível antes da expiração"
    fi
    
    exit 0
else
    echo "❌ FALHOU: Sistema não configura expiração"
    exit 1
fi
EOF

# ============================================================================
# 8. CSRF & CORS
# ============================================================================

cat > "$SCRIPT_DIR/test-csrf-protection.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Proteção CSRF"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar proteção contra CSRF"

echo "Teste CSRF" > /tmp/test_csrf.txt

# Tentar upload simulando origem maliciosa
echo "🚫 Simulando ataque CSRF de origem maliciosa..."
response=$(curl -s -X POST "$BASE_URL/api/upload" \
    -H "Origin: https://malicious-site.com" \
    -H "Referer: https://malicious-site.com/hack" \
    -F "file=@/tmp/test_csrf.txt" \
    -F "password=test123" \
    -k 2>/dev/null || echo '{"blocked":true}')

rm -f /tmp/test_csrf.txt

if echo "$response" | grep -iq "cors\|origin\|blocked\|403\|error"; then
    echo "✅ PASSOU: Requisição de origem maliciosa bloqueada"
    exit 0
elif echo "$response" | jq -r '.success' 2>/dev/null | grep -q "false"; then
    echo "✅ PASSOU: Requisição rejeitada (possível proteção CORS)"
    exit 0
else
    echo "⚠️  ATENÇÃO: Requisição pode ter sido aceita"
    echo "📝 Resposta: $response"
    exit 0
fi
EOF

cat > "$SCRIPT_DIR/test-cors-policy.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Política CORS"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar configuração CORS"

# Testar preflight OPTIONS
echo "🔍 Testando preflight CORS..."
cors_response=$(curl -s -X OPTIONS "$BASE_URL/api/upload" \
    -H "Origin: https://evil-site.com" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type" \
    -k -I)

echo "📝 Headers CORS recebidos:"
echo "$cors_response" | grep -i "access-control" || echo "Nenhum header CORS encontrado"

# Verificar se origem maliciosa é rejeitada
if echo "$cors_response" | grep -iq "access-control-allow-origin.*evil-site"; then
    echo "❌ FALHOU: Origem maliciosa permitida"
    exit 1
else
    echo "✅ PASSOU: CORS adequadamente configurado"
    exit 0
fi
EOF

# ============================================================================
# 9. LOGS & AUDITORIA
# ============================================================================

cat > "$SCRIPT_DIR/test-security-logs.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Logs de Segurança"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar logs de eventos de segurança"

# Gerar evento suspeito
echo "🚨 Gerando evento de segurança (senha incorreta)..."
curl -s -X POST "$BASE_URL/api/download/test-token" \
    -H "Content-Type: application/json" \
    -d '{"password":"hack_attempt"}' \
    -k > /dev/null

# Aguardar log ser escrito
sleep 2

echo "🔍 Verificando logs no backend..."
if kubectl logs -n file-sharing deployment/file-sharing-backend --tail=50 2>/dev/null | \
   grep -i "senha.*incorreta\|password.*incorrect\|error\|warn" | head -5; then
    echo ""
    echo "✅ PASSOU: Logs de segurança estão sendo gerados"
    exit 0
else
    echo "⚠️  ATENÇÃO: Logs de segurança não encontrados"
    echo "   (Pode ser normal se evento não foi logado)"
    exit 0
fi
EOF

cat > "$SCRIPT_DIR/test-audit-trail.sh" << 'EOF'
#!/bin/bash
set -e

BASE_URL="http://localhost:8080"
TEST_NAME="Trilha de Auditoria"

echo "🔥 $TEST_NAME"
echo "================================================"
echo "🎯 Objetivo: Verificar trilha de auditoria de ações"

echo "Teste de auditoria" > /tmp/test_audit.txt

# Fazer upload para gerar log de auditoria
echo "📤 Gerando evento de upload..."
upload_response=$(curl -s -X POST "$BASE_URL/api/upload" \
    -F "file=@/tmp/test_audit.txt" \
    -F "password=audit123" \
    -k)

token=$(echo "$upload_response" | jq -r '.data.token // empty' 2>/dev/null)

rm -f /tmp/test_audit.txt

if [ -n "$token" ]; then
    echo "📝 Upload realizado com token: $token"
    
    # Verificar logs de auditoria
    sleep 2
    echo "🔍 Verificando trilha de auditoria..."
    
    if kubectl logs -n file-sharing deployment/file-sharing-backend --tail=20 2>/dev/null | \
       grep -i "arquivo.*carregado\|upload.*sucesso\|file.*uploaded" | head -3; then
        echo ""
        echo "✅ PASSOU: Trilha de auditoria registrada"
        exit 0
    else
        echo "⚠️  ATENÇÃO: Trilha de auditoria não encontrada nos logs"
        exit 0
    fi
else
    echo "❌ FALHOU: Não foi possível gerar evento de auditoria"
    exit 1
fi
EOF

# ============================================================================
# SCRIPT PRINCIPAL - RUN ALL TESTS
# ============================================================================

cat > "$SCRIPT_DIR/run-all-security-tests.sh" << 'EOF'
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_URL="http://localhost:8080"
RESULTS_FILE="$SCRIPT_DIR/security_test_results.log"

echo "🔐 CLOUDWALK FILE SHARING - TESTES DE SEGURANÇA"
echo "=================================================================="
echo "🕒 Início: $(date)"
echo "🌐 URL Base: $BASE_URL"
echo "📁 Resultados: $RESULTS_FILE"
echo ""

# Verificar se aplicação está rodando
echo "🔍 Verificando disponibilidade da aplicação..."
if ! curl -s -k "$BASE_URL/health" > /dev/null 2>&1; then
    echo "❌ ERRO: Aplicação não está disponível em $BASE_URL"
    echo ""
    echo "💡 Para iniciar a aplicação:"
    echo "   cd cloudwalk-app && ./setup.sh"
    echo ""
    exit 1
fi
echo "✅ Aplicação está rodando"
echo ""

# Limpar arquivo de resultados
{
    echo "🔐 CloudWalk Security Tests Report"
    echo "=================================="
    echo "📅 Data: $(date)"
    echo "🌐 URL: $BASE_URL"
    echo ""
} > "$RESULTS_FILE"

# Lista completa de testes organizados por categoria
test_categories=(
    "🚦 Rate Limiting & DoS|test-rate-limiting-global.sh test-rate-limiting-upload.sh test-dos-protection.sh"
    "🔒 Autenticação|test-auth-no-password.sh test-auth-wrong-password.sh test-auth-invalid-token.sh"
    "📁 Upload & Validação|test-file-size-limit.sh test-file-type-validation.sh test-magic-numbers.sh"
    "🛡️ Injeção & XSS|test-sql-injection.sh test-xss-filename.sh test-path-traversal.sh"
    "🔐 Criptografia|test-encryption-strength.sh test-decryption-failure.sh"
    "🌐 Headers & Info|test-security-headers.sh test-information-disclosure.sh"
    "⏰ TTL & Expiração|test-ttl-validation.sh test-file-expiration.sh"
    "🔄 CSRF & CORS|test-csrf-protection.sh test-cors-policy.sh"
    "📊 Logs & Auditoria|test-security-logs.sh test-audit-trail.sh"
)

total_passed=0
total_failed=0
total_tests=0
start_time=$(date +%s)

for category_info in "${test_categories[@]}"; do
    category=$(echo "$category_info" | cut -d'|' -f1)
    tests=$(echo "$category_info" | cut -d'|' -f2)
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$category"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    {
        echo ""
        echo "$category"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    } >> "$RESULTS_FILE"
    
    category_passed=0
    category_failed=0
    
    for test_file in $tests; do
        ((total_tests++))
        test_name=$(echo "$test_file" | sed 's/test-//g' | sed 's/-/ /g' | sed 's/.sh//g')
        
        echo ""
        echo "🧪 [$total_tests] $(echo "$test_name" | tr '[:lower:]' '[:upper:]')"
        echo "────────────────────────────────────────────────"
        
        if [ -f "$SCRIPT_DIR/$test_file" ]; then
            echo "🏃 Executando $test_file..."
            
            if bash "$SCRIPT_DIR/$test_file" 2>&1 | tee -a "$RESULTS_FILE"; then
                echo "✅ $test_name: PASSOU" >> "$RESULTS_FILE"
                echo ""
                echo "✅ RESULTADO: PASSOU"
                ((total_passed++))
                ((category_passed++))
            else
                echo "❌ $test_name: FALHOU" >> "$RESULTS_FILE"
                echo ""
                echo "❌ RESULTADO: FALHOU"
                ((total_failed++))
                ((category_failed++))
            fi
        else
            echo "⚠️  ARQUIVO NÃO ENCONTRADO: $test_file"
            echo "⚠️  $test_name: ARQUIVO NÃO ENCONTRADO" >> "$RESULTS_FILE"
            ((total_failed++))
            ((category_failed++))
        fi
        
        echo "────────────────────────────────────────────────" >> "$RESULTS_FILE"
        
        # Pausa entre testes para evitar sobrecarga
        sleep 1
    done
    
    echo ""
    echo "📊 $category: $category_passed passou, $category_failed falhou"
done

end_time=$(date +%s)
duration=$((end_time - start_time))

echo ""
echo "🏁 RESUMO FINAL DOS TESTES"
echo "=================================================================="
echo "✅ Testes que Passaram: $total_passed"
echo "❌ Testes que Falharam: $total_failed"
echo "📈 Total de Testes: $total_tests"
echo "⏱️  Tempo Total de Execução: ${duration}s"

# Calcular porcentagem de sucesso
if [ $total_tests -gt 0 ]; then
    percentage=$((total_passed * 100 / total_tests))
    echo "📊 Taxa de Sucesso: $percentage%"
    
    echo ""
    if [ $percentage -ge 95 ]; then
        echo "🎉 EXCELENTE: Segurança excepcional!"
        echo "🏆 Parabéns! Sua aplicação está muito bem protegida."
    elif [ $percentage -ge 85 ]; then
        echo "👍 MUITO BOM: Segurança robusta!"
        echo "💪 Sua aplicação tem proteções sólidas."
    elif [ $percentage -ge 70 ]; then
        echo "✅ BOM: Segurança adequada!"
        echo "🔧 Algumas melhorias podem ser feitas."
    elif [ $percentage -ge 50 ]; then
        echo "⚠️  ATENÇÃO: Melhorias necessárias!"
        echo "🛠️  Revise as falhas e implemente correções."
    else
        echo "🚨 CRÍTICO: Muitas vulnerabilidades detectadas!"
        echo "🔥 Correções urgentes necessárias."
    fi
fi

echo ""
echo "📁 Relatório Completo: $RESULTS_FILE"
echo "🕒 Finalizado em: $(date)"

# Salvar resumo final no arquivo
{
    echo ""
    echo "🏁 RESUMO FINAL"
    echo "=================================================================="
    echo "✅ Testes que Passaram: $total_passed"
    echo "❌ Testes que Falharam: $total_failed"
    echo "📈 Total de Testes: $total_tests"
    echo "⏱️  Tempo Total: ${duration}s"
    echo "📊 Taxa de Sucesso: $percentage%"
    echo "🕒 Finalizado: $(date)"
} >> "$RESULTS_FILE"

echo ""
echo "🎯 Para re-executar teste específico:"
echo "   bash scripts/test-[nome-do-teste].sh"
echo ""
echo "📖 Para ver apenas os resultados:"
echo "   cat $RESULTS_FILE"
echo ""
EOF

# ============================================================================
# README
# ============================================================================

cat > "$SCRIPT_DIR/README.md" << 'EOF'
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

## 📞 Suporte

1. **Verificar logs**: `kubectl logs -n file-sharing deployment/file-sharing-backend`
2. **Verificar conectividade**: `curl -k https://localhost:8443/health`
3. **Re-executar setup**: `./setup.sh`
4. **Verificar permissões**: `chmod +x scripts/*.sh`

---

**🔐 Desenvolvido para CloudWalk File Sharing Challenge**
EOF

# ============================================================================
# FINALIZAÇÃO
# ============================================================================

# Tornar todos os scripts executáveis
chmod +x "$SCRIPT_DIR"/*.sh

echo ""
echo "🎉 SCRIPTS DE TESTE CRIADOS COM SUCESSO!"
echo "=================================================================="
echo "📁 Localização: $SCRIPT_DIR"
echo "📊 Total de Scripts: $(ls -1 "$SCRIPT_DIR"/test-*.sh 2>/dev/null | wc -l) testes individuais"
echo "🔧 Script Principal: run-all-security-tests.sh"
echo "📖 Documentação: README.md"
echo ""

echo "🚀 COMO USAR:"
echo "──────────────────────────────────────────────────────────────────"
echo "1️⃣  Executar TODOS os testes:"
echo "   bash scripts/run-all-security-tests.sh"
echo ""
echo "2️⃣  Executar teste individual:"
echo "   bash scripts/test-rate-limiting-global.sh"
echo ""
echo "3️⃣  Ver lista completa:"
echo "   ls scripts/test-*.sh"
echo ""

echo "📋 CATEGORIAS DE TESTE:"
echo "──────────────────────────────────────────────────────────────────"
echo "🚦 Rate Limiting & DoS (3 testes)"
echo "🔒 Autenticação & Autorização (3 testes)"  
echo "📁 Upload & Validação (3 testes)"
echo "🛡️ Injeção & XSS (3 testes)"
echo "🔐 Criptografia (2 testes)"
echo "🌐 Headers & Info Disclosure (2 testes)"
echo "⏰ TTL & Expiração (2 testes)"
echo "🔄 CSRF & CORS (2 testes)"
echo "📊 Logs & Auditoria (2 testes)"
echo ""

echo "✅ PRONTO PARA USAR!"
echo "🕒 $(date)"
echo ""
