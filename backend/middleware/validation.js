const validator = require('validator');

// Input validation middleware
const validateRegistration = (req, res, next) => {
  const { email, username, password } = req.body;
  const errors = [];

  // Email validation
  if (!email || !validator.isEmail(email)) {
    errors.push('Valid email is required');
  }

  // Username validation
  if (!username || username.length < 3 || username.length > 30) {
    errors.push('Username must be between 3 and 30 characters');
  }

  // Check for valid username characters (alphanumeric, underscore, dash)
  if (username && !validator.matches(username, /^[a-zA-Z0-9_-]+$/)) {
    errors.push('Username can only contain letters, numbers, underscores, and dashes');
  }

  // Password validation
  if (!password || password.length < 6) {
    errors.push('Password must be at least 6 characters long');
  }

  if (errors.length > 0) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors
    });
  }

  next();
};

const validateLogin = (req, res, next) => {
  const { email, password } = req.body;
  const errors = [];

  if (!email || !validator.isEmail(email)) {
    errors.push('Valid email is required');
  }

  if (!password || password.trim().length === 0) {
    errors.push('Password is required');
  }

  if (errors.length > 0) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors
    });
  }

  next();
};

const validatePasswordReset = (req, res, next) => {
  const { email } = req.body;
  const errors = [];

  if (!email || !validator.isEmail(email)) {
    errors.push('Valid email is required');
  }

  if (errors.length > 0) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors
    });
  }

  next();
};

const sanitizeInput = (req, res, next) => {
  // Trim string inputs (removed HTML escaping as it should be done on output, not input)
  const sanitizeString = (str) => {
    if (typeof str !== 'string') return str;
    return str.trim();
  };

  // Sanitize request body
  if (req.body) {
    Object.keys(req.body).forEach(key => {
      if (typeof req.body[key] === 'string') {
        req.body[key] = sanitizeString(req.body[key]);
      }
    });
  }

  // Sanitize query parameters
  if (req.query) {
    Object.keys(req.query).forEach(key => {
      if (typeof req.query[key] === 'string') {
        req.query[key] = sanitizeString(req.query[key]);
      }
    });
  }

  next();
};

module.exports = {
  validateRegistration,
  validateLogin,
  validatePasswordReset,
  sanitizeInput
};
