const logger = require('winston');

/**
 * Classe personalizada para erros da aplicação
 */
class AppError extends Error {
  constructor(message, statusCode, isOperational = true) {
    super(message);
    
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = isOperational;
    
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Middleware de tratamento de erros
 */
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log do erro
  logger.error('Erro capturado:', {
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });

  // Erro de validação do Joi
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map(val => val.message);
    error = new AppError(message, 400);
  }

  // Erro de cast do MongoDB (se estivéssemos usando)
  if (err.name === 'CastError') {
    const message = 'Recurso não encontrado';
    error = new AppError(message, 404);
  }

  // Erro de duplicação no MongoDB (se estivéssemos usando)
  if (err.code === 11000) {
    const message = 'Recurso já existe';
    error = new AppError(message, 400);
  }

  // Erro de JWT inválido
  if (err.name === 'JsonWebTokenError') {
    const message = 'Token inválido';
    error = new AppError(message, 401);
  }

  // Erro de JWT expirado
  if (err.name === 'TokenExpiredError') {
    const message = 'Token expirado';
    error = new AppError(message, 401);
  }

  // Erro de Multer
  if (err.name === 'MulterError') {
    let message = 'Erro no upload do arquivo';
    
    switch (err.code) {
      case 'LIMIT_FILE_SIZE':
        message = 'Arquivo muito grande';
        break;
      case 'LIMIT_FILE_COUNT':
        message = 'Muitos arquivos';
        break;
      case 'LIMIT_UNEXPECTED_FILE':
        message = 'Campo de arquivo inesperado';
        break;
      case 'LIMIT_PART_COUNT':
        message = 'Muitas partes no formulário';
        break;
    }
    
    error = new AppError(message, 400);
  }

  // Resposta para ambiente de desenvolvimento
  if (process.env.NODE_ENV === 'development') {
    return res.status(error.statusCode || 500).json({
      success: false,
      error: {
        message: error.message,
        status: error.status,
        statusCode: error.statusCode,
        stack: error.stack
      }
    });
  }

  // Resposta para ambiente de produção
  // Só mostrar erros operacionais para o cliente
  if (error.isOperational) {
    return res.status(error.statusCode || 500).json({
      success: false,
      error: {
        message: error.message
      }
    });
  } else {
    // Erro de programação - não vazar detalhes
    logger.error('Erro de programação:', err);
    
    return res.status(500).json({
      success: false,
      error: {
        message: 'Algo deu errado!'
      }
    });
  }
};

/**
 * Middleware para capturar rotas não encontradas
 */
const notFound = (req, res, next) => {
  const error = new AppError(`Rota ${req.originalUrl} não encontrada`, 404);
  next(error);
};

/**
 * Handler para rejections não capturadas
 */
process.on('unhandledRejection', (err, promise) => {
  logger.error('Unhandled Promise Rejection:', err);
  // Fechar servidor graciosamente
  server.close(() => {
    process.exit(1);
  });
});

/**
 * Handler para exceções não capturadas
 */
process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});

module.exports = {
  AppError,
  errorHandler,
  notFound
};
