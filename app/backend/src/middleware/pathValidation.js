const path = require('path');
const { AppError } = require('./errorHandler');

/**
 * Middleware para prevenir path traversal
 */
const preventPathTraversal = (req, res, next) => {
    const originalUrl = req.originalUrl;
    
    // Detectar tentativas de path traversal
    const dangerousPatterns = [
        /\.\./,                    // .. (directory traversal)
        /\%2e\%2e/i,              // URL encoded ..
        /\%2f/i,                  // URL encoded /
        /\%5c/i,                  // URL encoded \
        /\/etc\/passwd/i,         // Tentativa de acessar passwd
        /\/proc\//i,              // Tentativa de acessar proc
        /\/var\/log/i,            // Tentativa de acessar logs
        /\/root\//i,              // Tentativa de acessar root
        /\/home\//i,              // Tentativa de acessar home
        /\\windows\\system32/i,   // Tentativa Windows
        /\\boot\\.ini/i           // Tentativa Windows boot
    ];
    
    for (const pattern of dangerousPatterns) {
        if (pattern.test(originalUrl)) {
            console.log(`🚨 Path traversal tentativa bloqueada: ${originalUrl} de IP: ${req.ip}`);
            return next(new AppError('Acesso negado', 403));
        }
    }
    
    next();
};

module.exports = { preventPathTraversal };
