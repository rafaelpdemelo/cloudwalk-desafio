const path = require('path');

// Função para converter strings de tamanho (ex: "50mb", "1gb") para bytes
function parseSize(sizeStr) {
  if (!sizeStr) return null;
  
  const str = sizeStr.toString().toLowerCase().trim();
  const match = str.match(/^(\d+(?:\.\d+)?)\s*(b|kb|mb|gb|tb)?$/);
  
  if (!match) return null;
  
  const value = parseFloat(match[1]);
  const unit = match[2] || 'b';
  
  const multipliers = {
    'b': 1,
    'kb': 1024,
    'mb': 1024 * 1024,
    'gb': 1024 * 1024 * 1024,
    'tb': 1024 * 1024 * 1024 * 1024
  };
  
  return Math.floor(value * multipliers[unit]);
}

module.exports = {
  // Configurações de porta e ambiente
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // Configurações de upload
  upload: {
    maxFileSize: parseSize(process.env.MAX_FILE_SIZE) || 50 * 1024 * 1024, // 50MB
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
