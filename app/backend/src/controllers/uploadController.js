const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const { v4: uuidv4 } = require('uuid');
const sanitize = require('sanitize-filename');
// const { FileTypeResult } = require('file-type'); // Será importado dinamicamente

const config = require('../config/config');
const encryptionService = require('../utils/encryption');
const { AppError } = require('../middleware/errorHandler');
const logger = require('winston');

// Configuração do multer para upload
const storage = multer.memoryStorage();

const upload = multer({
  storage: storage,
  limits: {
    fileSize: config.upload.maxFileSize,
    files: 1
  },
  fileFilter: (req, file, cb) => {
    // Validar tipo MIME básico
    if (config.upload.allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new AppError(`Tipo de arquivo não permitido: ${file.mimetype}`, 400), false);
    }
  }
}).single('file');

// Store temporário para metadados dos arquivos
// Em produção, isso deveria ser Redis ou banco de dados
const fileMetadata = new Map();

/**
 * Controller para upload de arquivos
 */
class UploadController {
  
  /**
   * Processa o upload de um arquivo
   */
  async uploadFile(req, res, next) {
    const self = this; // Preservar referência do this
    
    try {
      // Usar multer para processar o upload
      upload(req, res, async (err) => {
        if (err instanceof multer.MulterError) {
          if (err.code === 'LIMIT_FILE_SIZE') {
            return next(new AppError('Arquivo muito grande. Máximo: 50MB', 400));
          }
          return next(new AppError(`Erro no upload: ${err.message}`, 400));
        } else if (err) {
          return next(err);
        }

        // Verificar se arquivo foi enviado
        if (!req.file) {
          return next(new AppError('Nenhum arquivo foi enviado', 400));
        }

        const { password, ttl } = req.body;

        // Validar senha
        if (!password || password.length < 4) {
          return next(new AppError('Senha deve ter pelo menos 4 caracteres', 400));
        }

        if (password.length > 128) {
          return next(new AppError('Senha muito longa. Máximo: 128 caracteres', 400));
        }

        try {
          await self.processFileUpload(req.file, password, ttl, req, res, next);
        } catch (error) {
          logger.error('Erro no processamento do arquivo:', error);
          return next(new AppError('Erro interno no processamento', 500));
        }
      });
    } catch (error) {
      logger.error('Erro no upload:', error);
      return next(new AppError('Erro interno no upload', 500));
    }
  }

  /**
   * Processa o arquivo após upload
   */
  async processFileUpload(file, password, ttl, req, res, next) {
    const token = encryptionService.generateToken();
    const sanitizedFilename = sanitize(file.originalname);
    const tempFilePath = path.join(config.paths.temp, `temp_${token}`);
    const encryptedFilePath = path.join(config.paths.uploads, `${token}.enc`);

    try {
      // Salvar arquivo temporário
      await fs.writeFile(tempFilePath, file.buffer);

      // Validar tipo de arquivo real (magic numbers)
      const fileType = await this.validateFileType(tempFilePath, file.mimetype);

      // Criptografar arquivo
      const encryptionInfo = await encryptionService.encryptFile(
        tempFilePath, 
        encryptedFilePath, 
        password
      );

      // Calcular hash para verificação de integridade
      const fileHash = await encryptionService.calculateFileHash(tempFilePath);

      // Definir TTL (Time To Live)
      const expiresAt = ttl ? 
        Date.now() + (parseInt(ttl) * 60 * 60 * 1000) : // TTL em horas
        Date.now() + config.security.defaultTTL;

      // Armazenar metadados do arquivo
      const metadata = {
        token,
        originalName: sanitizedFilename,
        mimeType: fileType.mime || file.mimetype,
        size: file.size,
        encryptedPath: encryptedFilePath,
        passwordHash: encryptionService.hashPassword(password),
        uploadedAt: new Date().toISOString(),
        expiresAt: new Date(expiresAt).toISOString(),
        downloads: 0,
        maxDownloads: 10, // Limite de downloads
        fileHash,
        encryption: encryptionInfo
      };

      fileMetadata.set(token, metadata);

      // Limpar arquivo temporário
      await fs.unlink(tempFilePath);

      // Log de auditoria
      logger.info('Arquivo carregado com sucesso', {
        token,
        filename: sanitizedFilename,
        size: file.size,
        ip: req.ip,
        userAgent: req.get('User-Agent')
      });

      // Resposta para o cliente
      res.status(201).json({
        success: true,
        data: {
          token,
          downloadUrl: (() => {
            // Se BASE_URL estiver configurada, usar ela (produção)
            if (config.baseUrl) {
              return `${config.baseUrl}/download/${token}`;
            }
            
            // Detectar automaticamente baseado no host e headers
            const host = req.get('host');
            const protocol = req.get('x-forwarded-proto') || req.protocol;
            
            // Para desenvolvimento local com port-forward
            if (host && host.includes('localhost')) {
              // Se a requisição vier do backend direto (localhost:3001)
              // redirecionar para o frontend (localhost:3000)
              if (host.includes(':3001')) {
                return `${protocol}://localhost:3000/download/${token}`;
              }
              // Para outros casos localhost, usar como está
              return `${protocol}://${host}/download/${token}`;
            }
            
            // Para outros casos (proxy, ingress, etc), usar o host como está
            return `${protocol}://${host}/download/${token}`;
          })(),
          filename: sanitizedFilename,
          size: file.size,
          expiresAt: new Date(expiresAt).toISOString(),
          maxDownloads: metadata.maxDownloads
        }
      });

    } catch (error) {
      // Limpar arquivos em caso de erro
      try {
        await fs.unlink(tempFilePath).catch(() => {});
        await fs.unlink(encryptedFilePath).catch(() => {});
      } catch (cleanupError) {
        logger.error('Erro na limpeza de arquivos:', cleanupError);
      }

      logger.error('Erro no processamento do arquivo:', error);
      return next(new AppError('Erro no processamento do arquivo', 500));
    }
  }

  /**
   * Valida o tipo real do arquivo usando magic numbers
   */
  async validateFileType(filePath, declaredMimeType) {
    try {
      const fileType = await import('file-type');
      const result = await fileType.fileTypeFromFile(filePath);
      
      if (!result) {
        // Se não conseguir detectar, usar o tipo declarado se estiver na lista permitida
        if (config.upload.allowedMimeTypes.includes(declaredMimeType)) {
          return { mime: declaredMimeType };
        }
        throw new AppError('Tipo de arquivo não identificado', 400);
      }

      // Verificar se o tipo detectado está na lista permitida
      if (!config.upload.allowedMimeTypes.includes(result.mime)) {
        throw new AppError(`Tipo de arquivo não permitido: ${result.mime}`, 400);
      }

      // Verificar se o tipo declarado corresponde ao detectado (spoofing protection)
      if (declaredMimeType !== result.mime) {
        logger.warn('Possível spoofing de tipo de arquivo detectado', {
          declared: declaredMimeType,
          detected: result.mime
        });
      }

      return result;
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      logger.error('Erro na validação de tipo de arquivo:', error);
      throw new AppError('Erro na validação do arquivo', 500);
    }
  }

  /**
   * Getter para metadados (para uso interno/testes)
   */
  getFileMetadata(token) {
    return fileMetadata.get(token);
  }

  /**
   * Limpa arquivos expirados
   */
  async cleanupExpiredFiles() {
    const now = Date.now();
    
    for (const [token, metadata] of fileMetadata.entries()) {
      if (new Date(metadata.expiresAt).getTime() < now) {
        try {
          // Remover arquivo criptografado
          await fs.unlink(metadata.encryptedPath).catch(() => {});
          
          // Remover metadados
          fileMetadata.delete(token);
          
          logger.info('Arquivo expirado removido', { token, filename: metadata.originalName });
        } catch (error) {
          logger.error('Erro ao remover arquivo expirado:', error);
        }
      }
    }
  }
}

// Executar limpeza de arquivos expirados a cada hora
setInterval(() => {
  new UploadController().cleanupExpiredFiles();
}, 60 * 60 * 1000);

module.exports = new UploadController();
