const Joi = require('joi');
const { AppError } = require('./errorHandler');

/**
 * Middleware de validação usando Joi
 */
const validateRequest = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body);
    
    if (error) {
      const message = error.details.map(detail => detail.message).join(', ');
      return next(new AppError(message, 400));
    }
    
    next();
  };
};

/**
 * Schemas de validação
 */
const schemas = {
  upload: Joi.object({
    password: Joi.string().min(4).max(128).required(),
    ttl: Joi.number().positive().optional()
  }),
  
  download: Joi.object({
    password: Joi.string().required()
  })
};

module.exports = {
  validateRequest,
  schemas
};
