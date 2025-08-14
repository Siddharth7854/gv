const jwt = require('jsonwebtoken');

// Middleware for admin authentication
const authenticateAdmin = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    console.log('🔍 Admin auth middleware - Header:', authHeader?.substring(0, 50) + '...');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.log('❌ No token provided or invalid format');
      return res.status(401).json({ error: 'No token provided' });
    }
    
    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    console.log('🎫 Token received:', token.substring(0, 20) + '...');
    
    // TEMPORARY: Handle hardcoded admin token (Base64 format)
    if (token.startsWith('YWRtaW46')) { // Base64 encoded 'admin:' prefix
      try {
        const decoded = Buffer.from(token, 'base64').toString('utf-8');
        console.log('🔓 Decoded Base64 token:', decoded.substring(0, 20) + '...');
        if (decoded.startsWith('admin:')) {
          console.log('✅ Hardcoded admin token accepted');
          req.admin = {
            admin_id: 1,
            username: 'admin',
            email: 'admin@system.com',
            full_name: 'System Administrator',
            role: 'super_admin',
            permissions: {}
          };
          return next();
        }
      } catch (base64Error) {
        console.log('❌ Base64 token decode failed:', base64Error.message);
      }
    }
    
    try {
      // Verify JWT token
      const jwtSecret = process.env.JWT_SECRET || 'your_super_secret_jwt_key_here_make_it_long_and_secure';
      const decoded = jwt.verify(token, jwtSecret);
      
      // Get SQLite database service from app
      const dbService = req.app.get('dbService');
      
      // Check if admin exists and is active (using SQLite column names)
      /* eslint-disable */
      const result = await dbService.query(
        'SELECT adminId, username, email, fullName, role FROM admins WHERE adminId = ? AND isActive = 1',
        [decoded.adminId || decoded.admin_id]
      );
      /* eslint-enable */

      if (result.length === 0) {
        return res.status(401).json({ error: 'Admin not found or inactive' });
      }

      const admin = result[0];
      req.admin = {
        adminId: admin.adminId,
        username: admin.username,
        email: admin.email,
        fullName: admin.fullName,
        role: admin.role
      };
      
      next();
    } catch (jwtError) {
      if (jwtError.name === 'TokenExpiredError') {
        return res.status(401).json({ error: 'Token expired' });
      } else if (jwtError.name === 'JsonWebTokenError') {
        return res.status(401).json({ error: 'Invalid token' });
      } else {
        throw jwtError;
      }
    }
  } catch (error) {
    console.error('Admin auth middleware error:', error);
    return res.status(500).json({ error: 'Authentication failed' });
  }
};

module.exports = { authenticateAdmin };
