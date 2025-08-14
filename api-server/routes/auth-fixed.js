// Fixed auth routes for SQLite with hybrid database service
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(__dirname, '..', 'uploads', 'profiles');
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'profile-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'), false);
    }
  }
});

// Helper function to get dbService from app
function getDbService(req) {
  return req.app.get('dbService');
}

// Register endpoint
router.post('/register', [
  body('fullName').notEmpty().withMessage('Full name is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('phoneNumber').isMobilePhone().withMessage('Valid phone number is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { fullName, email, phoneNumber, password } = req.body;
    const dbService = getDbService(req);

    // Check if user already exists
    const existingUser = await dbService.query(
      'SELECT * FROM users WHERE phoneNumber = ? OR email = ?',
      [phoneNumber, email]
    );

    if (existingUser && existingUser.length > 0) {
      return res.status(400).json({
        error: 'User already exists',
        message: 'A user with this phone number or email already exists'
      });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    // Generate user ID
    const userId = 'USER_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);

    // Insert new user
    await dbService.query(
      `INSERT INTO users (userId, email, fullName, phoneNumber, password, role, isActive, createdAt, updatedAt) 
       VALUES (?, ?, ?, ?, ?, 'citizen', 1, datetime('now'), datetime('now'))`,
      [userId, email, fullName, phoneNumber, passwordHash]
    );

    // Generate JWT token
    const token = jwt.sign(
      { userId, email, role: 'citizen' },
      process.env.JWT_SECRET || 'grievance_jwt_secret',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user: {
        userId,
        fullName,
        email,
        phoneNumber,
        role: 'citizen'
      },
      token
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Registration failed',
      message: 'Internal server error'
    });
  }
});

// Login endpoint
router.post('/login', [
  body('phoneNumber').isLength({ min: 10, max: 10 }).withMessage('Phone number must be 10 digits'),
  body('password').notEmpty().withMessage('Password is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { phoneNumber, password } = req.body;
    const dbService = getDbService(req);

    // Find user by phone number
    const result = await dbService.query(
      'SELECT * FROM users WHERE phoneNumber = ? AND isActive = 1',
      [phoneNumber]
    );

    if (!result || result.length === 0) {
      return res.status(401).json({
        error: 'Invalid credentials',
        message: 'Phone number or password is incorrect'
      });
    }

    const user = result[0];

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Invalid credentials',
        message: 'Phone number or password is incorrect'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.userId, email: user.email, role: user.role },
      process.env.JWT_SECRET || 'grievance_jwt_secret',
      { expiresIn: '7d' }
    );

    // Update FCM token if provided
    if (req.body.fcmToken) {
      await dbService.query(
        'UPDATE users SET fcmToken = ?, updatedAt = datetime("now") WHERE userId = ?',
        [req.body.fcmToken, user.userId]
      );
    }

    res.json({
      success: true,
      message: 'Login successful',
      user: {
        userId: user.userId,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: user.role,
        photoUrl: user.photoUrl
      },
      token
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Login failed',
      message: 'Internal server error'
    });
  }
});

// Profile endpoint
router.get('/profile', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'grievance_jwt_secret');
    const dbService = getDbService(req);

    const result = await dbService.query(
      'SELECT userId, fullName, email, phoneNumber, role, photoUrl, createdAt FROM users WHERE userId = ?',
      [decoded.userId]
    );

    if (!result || result.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      success: true,
      user: result[0]
    });

  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({
      error: 'Failed to fetch profile',
      message: 'Internal server error'
    });
  }
});

// Logout endpoint
router.post('/logout', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'grievance_jwt_secret');
    const dbService = getDbService(req);

    // Clear FCM token
    await dbService.query(
      'UPDATE users SET fcmToken = NULL, updatedAt = datetime("now") WHERE userId = ?',
      [decoded.userId]
    );

    res.json({
      success: true,
      message: 'Logout successful'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      error: 'Logout failed',
      message: 'Internal server error'
    });
  }
});

module.exports = router;
