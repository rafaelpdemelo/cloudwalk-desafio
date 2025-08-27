# Usando imagem Node.js oficial com Alpine para menor superfície de ataque
FROM node:18-alpine

# Criando usuário não-root para execução da aplicação
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Definindo diretório de trabalho
WORKDIR /app

# Copiando apenas package.json e package-lock.json primeiro (cache de layers)
COPY package*.json ./

# Instalando dependências de produção apenas
RUN npm ci --omit=dev && \
    npm cache clean --force

# Copiando código da aplicação
COPY src/ ./src/

# Criando diretórios necessários com permissões seguras
RUN mkdir -p /app/uploads /app/logs && \
    chown -R nextjs:nodejs /app && \
    chmod -R 755 /app && \
    chmod 775 /app/uploads /app/logs

# Removendo ferramentas desnecessárias para reduzir superfície de ataque
RUN apk del --purge

# Mudando para usuário não-root
USER nextjs

# Expondo porta da aplicação
EXPOSE 3000

# Health check para verificar se a aplicação está funcionando
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node src/healthcheck.js

# Comando para iniciar a aplicação
CMD ["npm", "start"]
