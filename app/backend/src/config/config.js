const path = require('path');

module.exports = {
  // Configurações de porta e ambiente
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // Configurações de upload
  upload: {
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE) || 100 * 1024 * 1024, // 100MB
    allowedMimeTypes: [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      'application/pdf',
      'text/plain',
      'application/zip',
      'application/x-zip-compressed',
      'application/json',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ],
    uploadPath: process.env.UPLOAD_PATH || '/app/uploads',
    tempPath: process.env.TEMP_PATH || '/tmp'
  },

  // Configurações de segurança
  security: {
    // TTL padrão para links (24 horas)
    defaultTTL: parseInt(process.env.DEFAULT_TTL) || 24 * 60 * 60 * 1000,
    
    // Configurações de criptografia
    encryption: {
      algorithm: 'aes-256-gcm',
      keyLength: 32,
      ivLength: 16,
      tagLength: 16
    },
    
    // Configurações de hash para senhas
    bcrypt: {
      saltRounds: 12
    },
    
    // Rate limiting
    rateLimit: {
      windowMs: 15 * 60 * 1000, // 15 minutos
      max: 100 // máximo de requests por janela
    }
  },

  // Configurações de Redis (se disponível)
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379,
    password: process.env.REDIS_PASSWORD || null,
    db: parseInt(process.env.REDIS_DB) || 0
  },

  // Configurações de logs
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    dir: process.env.LOG_DIR || 'logs'
  },

  // URLs permitidas para CORS
  corsOrigins: (process.env.CORS_ORIGINS || 'https://localhost:3001').split(','),

  // Configurações de paths
  paths: {
    uploads: process.env.UPLOAD_PATH || '/app/uploads',
    logs: process.env.LOG_DIR || 'logs',
    temp: process.env.TEMP_PATH || '/tmp'
  }
};
