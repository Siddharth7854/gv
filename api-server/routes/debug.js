// Simple admin login test endpoint for debugging
const express = require('express');
const router = express.Router();
// Use the shared dbService from app instead of direct import
// const dbService = require('../config/database');

router.post('/debug-login', async (req, res) => {
  try {
    console.log('=== DEBUG LOGIN ATTEMPT ===');
    console.log('Request body:', req.body);
    
    const { username, password } = req.body;
    
    // Get dbService from app
    const dbService = req.app.get('dbService');
    
    // Get admin from database
    const result = await dbService.query(
      'SELECT * FROM admins WHERE username = ?',
      [username]
    );
    
    console.log('Database result:', result);
    
    if (!result || result.length === 0) {
      console.log('No admin found');
      return res.json({ error: 'Admin not found' });
    }
    
    const admin = result[0];
    console.log('Found admin:', admin);
    
    // Simple password check for debugging
    if (password === 'admin123') {
      console.log('Password match - generating token');
      const token = `debug-token-${Date.now()}`;
      
      res.json({
        success: true,
        token: token,
        user: {
          admin_id: admin.admin_id,
          username: admin.username,
          role: admin.role
        },
        debug: 'Password matched'
      });
    } else {
      console.log('Password mismatch');
      res.json({ error: 'Password mismatch', debug: `Expected admin123, got ${password}` });
    }
    
  } catch (error) {
    console.error('Debug login error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

module.exports = router;
