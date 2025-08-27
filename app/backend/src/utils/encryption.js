const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');
const config = require('../config/config');

/**
 * Classe para criptografia de arquivos usando AES-256-GCM
 */
class EncryptionService {
  constructor() {
    this.algorithm = 'aes-256-cbc';
    this.keyLength = config.security.encryption.keyLength;
    this.ivLength = config.security.encryption.ivLength;
    this.tagLength = config.security.encryption.tagLength;
  }

  /**
   * Deriva uma chave de criptografia a partir da senha
   * @param {string} password - Senha fornecida pelo usuário
   * @param {Buffer} salt - Salt para derivação da chave
   * @returns {Buffer} Chave derivada
   */
  deriveKey(password, salt) {
    return crypto.pbkdf2Sync(password, salt, 100000, this.keyLength, 'sha256');
  }

  /**
   * Criptografa um arquivo
   * @param {string} inputPath - Caminho do arquivo original
   * @param {string} outputPath - Caminho do arquivo criptografado
   * @param {string} password - Senha para criptografia
   * @returns {Object} Informações sobre a criptografia (salt, iv, tag)
   */
  async encryptFile(inputPath, outputPath, password) {
    try {
      // Gerar salt e IV aleatórios
      const salt = crypto.randomBytes(32);
      const iv = crypto.randomBytes(this.ivLength);
      
      // Derivar chave da senha
      const key = this.deriveKey(password, salt);
      
      // Criar cipher
      const cipher = crypto.createCipher(this.algorithm, key, iv);
      
      // Ler arquivo original
      const inputData = await fs.readFile(inputPath);
      
      // Criptografar
      const encrypted = Buffer.concat([
        cipher.update(inputData),
        cipher.final()
      ]);
      
      // Para AES-CBC, usamos hash como "tag"
      const tag = crypto.createHash('sha256').update(encrypted).digest();
      
      // Criar arquivo criptografado com metadados
      const encryptedData = Buffer.concat([
        salt,           // 32 bytes
        iv,             // 16 bytes  
        tag,            // 32 bytes (SHA256)
        encrypted       // dados criptografados
      ]);
      
      // Salvar arquivo criptografado
      await fs.writeFile(outputPath, encryptedData);
      
      return {
        salt: salt.toString('hex'),
        iv: iv.toString('hex'),
        tag: tag.toString('hex'),
        encryptedSize: encryptedData.length
      };
    } catch (error) {
      throw new Error(`Erro na criptografia: ${error.message}`);
    }
  }

  /**
   * Descriptografa um arquivo
   * @param {string} inputPath - Caminho do arquivo criptografado
   * @param {string} outputPath - Caminho do arquivo descriptografado
   * @param {string} password - Senha para descriptografia
   * @returns {boolean} Sucesso da operação
   */
  async decryptFile(inputPath, outputPath, password) {
    try {
      // Ler arquivo criptografado
      const encryptedData = await fs.readFile(inputPath);
      
      // Extrair metadados
      const salt = encryptedData.slice(0, 32);
      const iv = encryptedData.slice(32, 48);
      const tag = encryptedData.slice(48, 80);  // 32 bytes para SHA256
      const encrypted = encryptedData.slice(80);
      
      // Derivar chave da senha
      const key = this.deriveKey(password, salt);
      
      // Verificar integridade com hash
      const expectedTag = crypto.createHash('sha256').update(encrypted).digest();
      if (!tag.equals(expectedTag)) {
        throw new Error('Arquivo corrompido ou senha incorreta');
      }
      
      // Criar decipher
      const decipher = crypto.createDecipher(this.algorithm, key, iv);
      
      // Descriptografar
      const decrypted = Buffer.concat([
        decipher.update(encrypted),
        decipher.final()
      ]);
      
      // Salvar arquivo descriptografado
      await fs.writeFile(outputPath, decrypted);
      
      return true;
    } catch (error) {
      // Se a descriptografia falhar, provavelmente a senha está incorreta
      if (error.message.includes('auth')) {
        throw new Error('Senha incorreta');
      }
      throw new Error(`Erro na descriptografia: ${error.message}`);
    }
  }

  /**
   * Gera um hash seguro da senha para validação
   * @param {string} password - Senha a ser hasheada
   * @returns {string} Hash da senha
   */
  hashPassword(password) {
    const salt = crypto.randomBytes(32);
    const hash = crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha256');
    return salt.toString('hex') + ':' + hash.toString('hex');
  }

  /**
   * Verifica se uma senha corresponde ao hash
   * @param {string} password - Senha a ser verificada
   * @param {string} storedHash - Hash armazenado
   * @returns {boolean} Senha é válida
   */
  verifyPassword(password, storedHash) {
    const [saltHex, hashHex] = storedHash.split(':');
    const salt = Buffer.from(saltHex, 'hex');
    const hash = crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha256');
    return hash.toString('hex') === hashHex;
  }

  /**
   * Gera um token único para o arquivo
   * @returns {string} Token UUID
   */
  generateToken() {
    return crypto.randomUUID();
  }

  /**
   * Calcula hash SHA-256 de um arquivo para verificação de integridade
   * @param {string} filePath - Caminho do arquivo
   * @returns {string} Hash SHA-256 do arquivo
   */
  async calculateFileHash(filePath) {
    const data = await fs.readFile(filePath);
    return crypto.createHash('sha256').update(data).digest('hex');
  }
}

module.exports = new EncryptionService();
