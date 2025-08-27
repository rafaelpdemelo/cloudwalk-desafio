const path = require('path');
const fs = require('fs').promises;
const { AppError } = require('../middleware/errorHandler');
const encryptionService = require('../utils/encryption');
const uploadController = require('./uploadController');
const logger = require('winston');
const config = require('../config/config');

/**
 * Controller para download de arquivos
 */
class DownloadController {

  /**
   * Obtém informações do arquivo para download (sem baixar)
   */
  async getFileInfo(req, res, next) {
    try {
      const { token } = req.params;

      // Validar token
      if (!token || !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(token)) {
        return next(new AppError('Token inválido', 400));
      }

      // Buscar metadados do arquivo
      const metadata = uploadController.getFileMetadata(token);
      
      if (!metadata) {
        return next(new AppError('Arquivo não encontrado', 404));
      }

      // Verificar se arquivo não expirou
      if (new Date(metadata.expiresAt) < new Date()) {
        return next(new AppError('Link expirado', 410));
      }

      // Verificar se ainda há downloads disponíveis
      if (metadata.downloads >= metadata.maxDownloads) {
        return next(new AppError('Limite de downloads excedido', 410));
      }

      // Verificar se arquivo ainda existe no disco
      try {
        await fs.access(metadata.encryptedPath);
      } catch (error) {
        logger.error('Arquivo criptografado não encontrado no disco:', {
          token,
          path: metadata.encryptedPath
        });
        return next(new AppError('Arquivo não disponível', 404));
      }

      // Log de tentativa de acesso
      logger.info('Informações do arquivo solicitadas', {
        token,
        ip: req.ip,
        userAgent: req.get('User-Agent')
      });

      // Retornar informações do arquivo
      res.status(200).json({
        success: true,
        data: {
          filename: metadata.originalName,
          size: metadata.size,
          uploadedAt: metadata.uploadedAt,
          expiresAt: metadata.expiresAt,
          downloads: metadata.downloads,
          maxDownloads: metadata.maxDownloads,
          remainingDownloads: metadata.maxDownloads - metadata.downloads
        }
      });

    } catch (error) {
      logger.error('Erro ao obter informações do arquivo:', error);
      return next(new AppError('Erro interno do servidor', 500));
    }
  }

  /**
   * Realiza o download do arquivo
   */
  async downloadFile(req, res, next) {
    const tempDecryptedPath = null;
    
    try {
      const { token } = req.params;
      const { password } = req.body;

      // Validar token
      if (!token || !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(token)) {
        return next(new AppError('Token inválido', 400));
      }

      // Validar senha
      if (!password) {
        return next(new AppError('Senha é obrigatória', 400));
      }

      // Buscar metadados do arquivo
      const metadata = uploadController.getFileMetadata(token);
      
      if (!metadata) {
        return next(new AppError('Arquivo não encontrado', 404));
      }

      // Verificar se arquivo não expirou
      if (new Date(metadata.expiresAt) < new Date()) {
        return next(new AppError('Link expirado', 410));
      }

      // Verificar se ainda há downloads disponíveis
      if (metadata.downloads >= metadata.maxDownloads) {
        return next(new AppError('Limite de downloads excedido', 410));
      }

      // Verificar se arquivo ainda existe no disco
      try {
        await fs.access(metadata.encryptedPath);
      } catch (error) {
        logger.error('Arquivo criptografado não encontrado no disco:', {
          token,
          path: metadata.encryptedPath
        });
        return next(new AppError('Arquivo não disponível', 404));
      }

      // Verificar senha
      if (!encryptionService.verifyPassword(password, metadata.passwordHash)) {
        logger.warn('Tentativa de download com senha incorreta', {
          token,
          ip: req.ip,
          userAgent: req.get('User-Agent')
        });
        return next(new AppError('Senha incorreta', 401));
      }

      // Criar arquivo temporário para descriptografia
      const tempDecryptedPath = path.join(config.paths.temp, `decrypt_${token}_${Date.now()}`);

      // Descriptografar arquivo
      try {
        await encryptionService.decryptFile(
          metadata.encryptedPath,
          tempDecryptedPath,
          password
        );
      } catch (error) {
        if (error.message.includes('Senha incorreta')) {
          return next(new AppError('Senha incorreta', 401));
        }
        logger.error('Erro na descriptografia:', error);
        return next(new AppError('Erro na descriptografia do arquivo', 500));
      }

      // Verificar integridade do arquivo descriptografado
      const currentHash = await encryptionService.calculateFileHash(tempDecryptedPath);
      if (currentHash !== metadata.fileHash) {
        logger.error('Falha na verificação de integridade do arquivo', {
          token,
          expectedHash: metadata.fileHash,
          currentHash
        });
        
        // Limpar arquivo temporário
        await fs.unlink(tempDecryptedPath).catch(() => {});
        
        return next(new AppError('Arquivo corrompido', 500));
      }

      // Incrementar contador de downloads
      metadata.downloads += 1;

      // Log de download bem-sucedido
      logger.info('Download realizado com sucesso', {
        token,
        filename: metadata.originalName,
        downloads: metadata.downloads,
        ip: req.ip,
        userAgent: req.get('User-Agent')
      });

      // Configurar headers para download
      res.setHeader('Content-Disposition', `attachment; filename="${encodeURIComponent(metadata.originalName)}"`);
      res.setHeader('Content-Type', metadata.mimeType || 'application/octet-stream');
      res.setHeader('Content-Length', metadata.size);
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');

      // Enviar arquivo
      const fileBuffer = await fs.readFile(tempDecryptedPath);
      res.status(200).send(fileBuffer);

      // Limpar arquivo temporário após envio
      await fs.unlink(tempDecryptedPath).catch((error) => {
        logger.error('Erro ao remover arquivo temporário:', error);
      });

    } catch (error) {
      // Limpar arquivo temporário em caso de erro
      if (tempDecryptedPath) {
        await fs.unlink(tempDecryptedPath).catch(() => {});
      }

      logger.error('Erro no download:', error);
      
      if (error instanceof AppError) {
        return next(error);
      }
      
      return next(new AppError('Erro interno do servidor', 500));
    }
  }

  /**
   * Remove um arquivo manualmente (para administração)
   */
  async deleteFile(req, res, next) {
    try {
      const { token } = req.params;

      // Validar token
      if (!token || !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(token)) {
        return next(new AppError('Token inválido', 400));
      }

      // Buscar metadados do arquivo
      const metadata = uploadController.getFileMetadata(token);
      
      if (!metadata) {
        return next(new AppError('Arquivo não encontrado', 404));
      }

      // Remover arquivo criptografado
      try {
        await fs.unlink(metadata.encryptedPath);
      } catch (error) {
        logger.warn('Arquivo já foi removido do disco:', error);
      }

      // Remover metadados
      uploadController.getFileMetadata().delete(token);

      // Log de remoção
      logger.info('Arquivo removido manualmente', {
        token,
        filename: metadata.originalName,
        ip: req.ip,
        userAgent: req.get('User-Agent')
      });

      res.status(200).json({
        success: true,
        message: 'Arquivo removido com sucesso'
      });

    } catch (error) {
      logger.error('Erro ao remover arquivo:', error);
      return next(new AppError('Erro interno do servidor', 500));
    }
  }
}

module.exports = new DownloadController();
