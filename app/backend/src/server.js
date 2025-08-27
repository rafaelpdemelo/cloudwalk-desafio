const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const winston = require('winston');
const expressWinston = require('express-winston');

const config = require('./config/config');
const uploadController = require('./controllers/uploadController');
const downloadController = require('./controllers/downloadController');
const { errorHandler } = require('./middleware/errorHandler');
const { validateRequest } = require('./middleware/validation');
const { preventPathTraversal } = require('./middleware/pathValidation');

const app = express();

// Configurar trust proxy para rate limiting funcionar corretamente
app.set('trust proxy', true);

// Configuração de logging
const fs = require('fs');
const logsDir = '/app/logs';

// Criar diretório de logs se não existir
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'file-sharing-api' },
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

// Adicionar transports de arquivo apenas se o diretório for writable
try {
  logger.add(new winston.transports.File({ 
    filename: `${logsDir}/error.log`, 
    level: 'error',
    maxsize: 5242880, // 5MB
    maxFiles: 5
  }));
  logger.add(new winston.transports.File({ 
    filename: `${logsDir}/combined.log`,
    maxsize: 5242880, // 5MB
    maxFiles: 5
  }));
} catch (error) {
  console.warn('Não foi possível configurar logs em arquivo:', error.message);
}

// Rate limiting mais rigoroso
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 50, // REDUZIR de 100 para 50 requests por IP
  message: {
    error: 'Muitas tentativas. Tente novamente em 15 minutos.'
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false
});

// Rate limiting específico para endpoints sensíveis
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10, // Apenas 10 tentativas de auth por 15 min
  message: {
    error: 'Muitas tentativas de autenticação. Aguarde 15 minutos.'
  }
});

// Slow down para uploads
const uploadLimiter = slowDown({
  windowMs: 15 * 60 * 1000, // 15 minutos
  delayAfter: 5, // permitir 5 requests sem delay
  delayMs: 500 // adicionar 500ms de delay a partir da 6ª request
});

// Middlewares de segurança
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"]
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

app.use(cors({
  origin: process.env.FRONTEND_URL || 'https://localhost:3001',
  credentials: true,
  optionsSuccessStatus: 200
}));

app.use(compression());
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ extended: true, limit: '100mb' }));

// Aplicar proteção contra path traversal ANTES das rotas
app.use(preventPathTraversal);

// Aplicar rate limiting
app.use('/api/', limiter);
app.use('/api/upload', uploadLimiter);

// Logging de requests
app.use(expressWinston.logger({
  winstonInstance: logger,
  meta: true,
  msg: "HTTP {{req.method}} {{req.url}}",
  expressFormat: true,
  colorize: false,
  ignoreRoute: function (req, res) { return false; }
}));

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Rotas da API
app.post('/api/upload', uploadController.uploadFile.bind(uploadController));
app.get('/api/download/:token', downloadController.getFileInfo);
app.post('/api/download/:token', authLimiter, downloadController.downloadFile);

// Middleware de tratamento de erros
app.use(expressWinston.errorLogger({
  winstonInstance: logger
}));

app.use(errorHandler);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint não encontrado'
  });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  logger.info(`Servidor rodando na porta ${PORT}`);
  logger.info(`Ambiente: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM recebido, encerrando servidor...');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT recebido, encerrando servidor...');
  process.exit(0);
});

module.exports = app;
