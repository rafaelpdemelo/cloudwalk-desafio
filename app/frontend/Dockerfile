# Multi-stage build para otimizar segurança e tamanho
FROM node:18-alpine AS builder

# Criando usuário não-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

WORKDIR /app

# Copiando arquivos de dependências
COPY package*.json ./

# Instalando dependências
RUN npm ci && \
    npm cache clean --force

# Copiando código fonte
COPY . .

# Build da aplicação
RUN npm run build

# Stage de produção usando nginx
FROM nginx:alpine

# Instalando dumb-init para melhor signal handling
RUN apk add --no-cache dumb-init

# Removendo usuário padrão do nginx e criando novo
RUN deluser nginx && \
    addgroup -g 1001 -S nginx && \
    adduser -D -S -u 1001 -G nginx nginx

# Copiando configuração customizada do nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Copiando arquivos buildados
COPY --from=builder /app/dist /usr/share/nginx/html

# Definindo permissões seguras
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d

# Criando diretórios necessários com permissões corretas
RUN touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

# Mudando para usuário não-root
USER nginx

# Expondo porta
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/ || exit 1

# Comando de inicialização
ENTRYPOINT ["dumb-init", "--"]
CMD ["nginx", "-g", "daemon off;"]
