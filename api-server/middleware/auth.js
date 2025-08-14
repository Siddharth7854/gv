const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  try {
    let token = req.headers.authorization || '';
    console.log('[AUTH DEBUG] Incoming Authorization header:', req.headers.authorization);
    token = token.replace('Bearer', '').replace(/\r?\n|\r/g, '').trim();
    console.log('[AUTH DEBUG] Parsed token:', token);

    if (!token) {
      console.log('[AUTH DEBUG] No token provided');
      return res.status(401).json({
        error: 'No token provided',
        message: 'Authentication token is required'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log('[AUTH DEBUG] Decoded user:', decoded);
    req.user = decoded;
    next();

  } catch (error) {
    console.log('[AUTH DEBUG] JWT error:', error);
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Invalid token',
        message: 'Authentication token is invalid'
      });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Token expired',
        message: 'Authentication token has expired'
      });
    }
    return res.status(401).json({
      error: 'Authentication failed',
      message: 'Invalid authentication credentials'
    });
  }
};

// Export both for compatibility
module.exports = authMiddleware;
module.exports.authenticateUser = authMiddleware;
