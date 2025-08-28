# Certificados TLS

Esta pasta contém os certificados TLS self-signed gerados automaticamente pelo script `setup.sh`.

## Arquivos Gerados Automaticamente

Os seguintes arquivos são gerados automaticamente e **NÃO** devem ser commitados no repositório:

- `ca.key` - Chave privada da CA
- `ca.crt` - Certificado da CA
- `ca.srl` - Arquivo de serial da CA
- `server.key` - Chave privada do servidor
- `server.crt` - Certificado do servidor
- `server.csr` - Certificate Signing Request
- `server.ext` - Arquivo de extensões para SAN

## Como Funciona

1. O script `setup.sh` executa a função `generate_certificates()`
2. Os certificados são gerados com OpenSSL
3. O certificado inclui os seguintes Subject Alternative Names (SAN):
   - `file-sharing.local`
   - `*.file-sharing.local`
   - `localhost`
   - `backend`
   - `frontend`
   - `127.0.0.1`
   - IP do Minikube

## Configuração

Os certificados são configurados para:
- **Organização**: CloudWalk
- **País**: BR (Brasil)
- **Estado**: SP (São Paulo)
- **Validade**: 365 dias
- **Algoritmo**: SHA256

## Uso

Os certificados são usados para:
- Proxy HTTPS local (`https://localhost:8080`)
- ArgoCD (`https://localhost:8443`)
- Ingress Kubernetes (quando configurado)

## Segurança

⚠️ **IMPORTANTE**: Estes são certificados self-signed para desenvolvimento local. 
Nunca use em produção!
