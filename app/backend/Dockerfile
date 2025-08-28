# Backend Dockerfile - Rootless
FROM node:18.20.4-alpine3.20

# Instalar dumb-init para melhor signal handling
RUN apk add --no-cache dumb-init

# Criar usuário não-root com IDs únicos
RUN addgroup -g 1003 -S nodejs && \
    adduser -S -u 1003 -G nodejs nodejs

# Definir diretório de trabalho
WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./

# Instalar dependências
RUN npm ci --only=production && npm cache clean --force

# Copiar código fonte
COPY src/ ./src/

# Criar diretório de uploads com permissões corretas
RUN mkdir -p /app/uploads && \
    chown -R nodejs:nodejs /app

# Mudando para usuário não-root
USER nodejs

# Expondo porta
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Comando de inicialização
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/server.js"]
