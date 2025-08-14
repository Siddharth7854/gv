require('dotenv').config();
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
// Use shared dbService from app instead of direct import
// const dbService = require('../config/database');

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
    cb(null, `profile-${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'));
    }
  }
});

// Authentication middleware
const authMiddleware = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        error: 'No token provided',
        message: 'Authentication token is required'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({
      error: 'Invalid token',
      message: 'Authentication token is invalid'
    });
  }
};

const router = express.Router();

// Register citizen
router.post('/register', [
  body('full_name').trim().isLength({ min: 2, max: 100 }).withMessage('Full name must be between 2 and 100 characters'),
  body('email').optional().isEmail().withMessage('Please provide a valid email'),
  body('phone').matches(/^\d{10}$/).withMessage('Phone number must be 10 digits'),
  body('aadhar_number').matches(/^\d{12}$/).withMessage('Aadhar number must be 12 digits'),
  body('district').trim().isLength({ min: 2, max: 50 }).withMessage('District is required'),
  body('block').trim().isLength({ min: 2, max: 50 }).withMessage('Block is required'),
  body('ward').trim().isLength({ min: 2, max: 50 }).withMessage('Ward is required'),
  body('address').trim().isLength({ min: 5, max: 500 }).withMessage('Address must be between 5 and 500 characters'),
  body('pincode').matches(/^\d{6}$/).withMessage('Pincode must be 6 digits'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        details: errors.array()
      });
    }

    const {
      full_name,
      email,
      phone,
      aadhar_number,
      district,
      block,
      ward,
      address,
      pincode,
      password
    } = req.body;

    // Get dbService from app
    const dbService = req.app.get('dbService');

    // Check if user already exists
    const existingUser = await dbService.query(
      'SELECT * FROM users WHERE phoneNumber = ? OR email = ?',
      [phone, email]
    );

    if (existingUser.recordset.length > 0) {
      return res.status(400).json({
        error: 'User already exists',
        message: 'A user with this phone number or Aadhar number already exists'
      });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    // Insert new citizen
    const result = await dbService.executeStoredProcedure('sp_RegisterCitizen', {
      full_name,
      email: email || `${phone}@citizen.gov.in`,
      phone,
      aadhar_number,
      district,
      block,
      ward,
      address,
      pincode,
      password_hash: passwordHash
    });

    const citizenId = result.recordset[0].citizen_id;

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      citizen_id: citizenId
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Registration failed',
      message: error.message
    });
  }
});

// Login
router.post('/login', [
  body('phone').matches(/^\d{10}$/).withMessage('Phone number must be 10 digits'),
  body('password').notEmpty().withMessage('Password is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        details: errors.array()
      });
    }

    const { phone, password } = req.body;
    const ip_address = req.ip || req.connection.remoteAddress;
    const user_agent = req.headers['user-agent'];

    // Get user from database
    const result = await dbService.executeQuery(
      'SELECT citizen_id, full_name, email, phone, password_hash, district, block, ward, photo_url FROM Citizens WHERE phone = @phone AND is_active = 1',
      { phone }
    );

    if (result.recordset.length === 0) {
      // Log failed login attempt if user exists but inactive
      const inactiveUser = await dbService.executeQuery(
        'SELECT citizen_id FROM Citizens WHERE phone = @phone',
        { phone }
      );
      
      if (inactiveUser.recordset.length > 0) {
        // Log failed login for inactive account
        await dbService.executeQuery(
          'EXEC SP_LogUserActivity @citizen_id, @activity_type, @activity_description, @ip_address, @user_agent, @session_id, @status',
          {
            citizen_id: inactiveUser.recordset[0].citizen_id,
            activity_type: 'Login',
            activity_description: 'Login attempt on inactive account',
            ip_address,
            user_agent,
            session_id: null,
            status: 'Failed'
          }
        );
      }

      return res.status(401).json({
        error: 'Invalid credentials',
        message: 'Phone number or password is incorrect'
      });
    }

    const user = result.recordset[0];

    // Check if user has active timeline controls that prevent login
    const controlsResult = await dbService.executeQuery(`
      SELECT control_type, reason 
      FROM UserTimelineControl 
      WHERE citizen_id = @citizen_id 
      AND is_active = 1 
      AND control_type IN ('Account_Suspension', 'Login_Restriction')
      AND (end_date IS NULL OR end_date > GETDATE())
    `, { citizen_id: user.citizen_id });

    if (controlsResult.recordset.length > 0) {
      const control = controlsResult.recordset[0];
      
      // Log blocked login attempt
      await dbService.executeQuery(
        'EXEC SP_LogUserActivity @citizen_id, @activity_type, @activity_description, @ip_address, @user_agent, @session_id, @status',
        {
          citizen_id: user.citizen_id,
          activity_type: 'Login',
          activity_description: `Login blocked due to ${control.control_type}: ${control.reason}`,
          ip_address,
          user_agent,
          session_id: null,
          status: 'Blocked'
        }
      );

      return res.status(403).json({
        error: 'Account Access Restricted',
        message: `Your account access has been restricted. Reason: ${control.reason}`,
        control_type: control.control_type
      });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      // Log failed login attempt
      await dbService.executeQuery(
        'EXEC SP_LogUserActivity @citizen_id, @activity_type, @activity_description, @ip_address, @user_agent, @session_id, @status',
        {
          citizen_id: user.citizen_id,
          activity_type: 'Login',
          activity_description: 'Invalid password attempt',
          ip_address,
          user_agent,
          session_id: null,
          status: 'Failed'
        }
      );

      return res.status(401).json({
        error: 'Invalid credentials',
        message: 'Phone number or password is incorrect'
      });
    }

    // Generate JWT token
    console.log('JWT_SECRET:', process.env.JWT_SECRET);
    const jwtSecret = process.env.JWT_SECRET || 'your_super_secret_jwt_key_here_make_it_long_and_secure';
    const token = jwt.sign(
      { 
        citizen_id: user.citizen_id, 
        phone: user.phone 
      },
      jwtSecret,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    // Generate session ID
    const session_id = `sess_${user.citizen_id}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Log successful login
    await dbService.executeQuery(
      'EXEC SP_LogUserActivity @citizen_id, @activity_type, @activity_description, @ip_address, @user_agent, @session_id, @status',
      {
        citizen_id: user.citizen_id,
        activity_type: 'Login',
        activity_description: 'Successful login',
        ip_address,
        user_agent,
        session_id,
        status: 'Success'
      }
    );

    // Create user session record
    await dbService.executeQuery(`
      INSERT INTO UserSessions (session_id, citizen_id, login_time, last_activity, ip_address, user_agent, is_active)
      VALUES (@session_id, @citizen_id, GETDATE(), GETDATE(), @ip_address, @user_agent, 1)
    `, {
      session_id,
      citizen_id: user.citizen_id,
      ip_address,
      user_agent
    });

    // Remove password from response
    delete user.password_hash;

    console.log(`✅ User ${user.full_name} (ID: ${user.citizen_id}) logged in successfully`);

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user,
      session_id
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Login failed',
      message: error.message
    });
  }
});

// Verify token
router.post('/verify', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        error: 'No token provided',
        message: 'Authentication token is required'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get updated user data
    const result = await dbService.executeQuery(
      'SELECT citizen_id, full_name, email, phone, district, block, ward, photo_url FROM Citizens WHERE citizen_id = @citizen_id AND is_active = 1',
      { citizen_id: decoded.citizen_id }
    );

    if (result.recordset.length === 0) {
      return res.status(401).json({
        error: 'Invalid token',
        message: 'User not found or inactive'
      });
    }

    res.json({
      success: true,
      valid: true,
      user: result.recordset[0]
    });

  } catch (error) {
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

    console.error('Token verification error:', error);
    res.status(500).json({
      error: 'Verification failed',
      message: error.message
    });
  }
});

// Upload profile photo (base64 approach for cross-platform compatibility)
router.put('/profile/photo', authMiddleware, async (req, res) => {
  try {
    const { citizen_id, photo_data, filename } = req.body;

    // Verify user can only update their own photo
    if (citizen_id !== req.user.citizen_id) {
      return res.status(403).json({
        error: 'Access denied',
        message: 'You can only update your own profile photo'
      });
    }

    if (!photo_data) {
      return res.status(400).json({
        error: 'No photo data provided',
        message: 'Please provide photo data in base64 format'
      });
    }

    // Save base64 image to file
    try {
      console.log('📁 Starting file save process...');
      const uploadsDir = path.join(__dirname, '..', 'uploads', 'profiles');
      console.log('📁 Upload directory:', uploadsDir);
      console.log('📁 Directory exists:', fs.existsSync(uploadsDir));
      
      if (!fs.existsSync(uploadsDir)) {
        console.log('📁 Creating directory...');
        fs.mkdirSync(uploadsDir, { recursive: true });
      }

      const fileName = filename || `profile-${citizen_id}-${Date.now()}.jpg`;
      const filePath = path.join(uploadsDir, fileName);
      console.log('📁 File path:', filePath);
      
      // Convert base64 to buffer and save
      const base64Data = photo_data.replace(/^data:image\/[a-z]+;base64,/, '');
      const buffer = Buffer.from(base64Data, 'base64');
      console.log('📁 Buffer size:', buffer.length);
      
      fs.writeFileSync(filePath, buffer);
      console.log('✅ File saved successfully to:', filePath);

      const photo_url = `/uploads/profiles/${fileName}`;
      console.log('📁 Photo URL:', photo_url);

      // Update profile photo in database
      await dbService.executeStoredProcedure('sp_UpdateProfilePhoto', {
        citizen_id,
        photo_url
      });

      res.json({
        success: true,
        message: 'Profile photo uploaded successfully',
        photo_url
      });

    } catch (fileError) {
      console.error('File save error:', fileError);
      return res.status(500).json({
        error: 'File save failed',
        message: 'Could not save uploaded photo'
      });
    }

  } catch (error) {
    console.error('Profile photo upload error:', error);
    res.status(500).json({
      error: 'Upload failed',
      message: error.message
    });
  }
});

// Upload profile photo (multipart approach)
router.post('/profile/photo/upload', authMiddleware, upload.single('photo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        error: 'No file uploaded',
        message: 'Please select a photo to upload'
      });
    }

    const citizen_id = req.user.citizen_id;
    const photo_url = `/uploads/profiles/${req.file.filename}`;

    // Update profile photo in database
    await dbService.executeStoredProcedure('sp_UpdateProfilePhoto', {
      citizen_id,
      photo_url
    });

    res.json({
      success: true,
      message: 'Profile photo uploaded successfully',
      photo_url
    });

  } catch (error) {
    console.error('Profile photo upload error:', error);
    
    // Clean up uploaded file if database update fails
    if (req.file) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (unlinkError) {
        console.error('Error cleaning up file:', unlinkError);
      }
    }
    
    res.status(500).json({
      error: 'Upload failed',
      message: error.message
    });
  }
});

// Remove profile photo
router.delete('/profile/photo/:citizen_id', authMiddleware, async (req, res) => {
  try {
    const citizen_id = parseInt(req.params.citizen_id);

    // Verify user can only update their own photo
    if (citizen_id !== req.user.citizen_id) {
      return res.status(403).json({
        error: 'Access denied',
        message: 'You can only update your own profile photo'
      });
    }

    await dbService.executeQuery(
      'UPDATE Citizens SET photo_url = NULL, updated_at = GETDATE() WHERE citizen_id = @citizen_id',
      { citizen_id }
    );

    res.json({
      success: true,
      message: 'Profile photo removed successfully'
    });

  } catch (error) {
    console.error('Profile photo remove error:', error);
    res.status(500).json({
      error: 'Remove failed',
      message: error.message
    });
  }
});

// Update profile information
router.put('/profile', authMiddleware, async (req, res) => {
  try {
    const { citizen_id, full_name, email, district, block, ward, address, photo_url } = req.body;

    // Verify user can only update their own profile
    if (citizen_id !== req.user.citizen_id) {
      return res.status(403).json({
        error: 'Access denied',
        message: 'You can only update your own profile'
      });
    }

    await dbService.executeStoredProcedure('sp_UpdateProfile', {
      citizen_id,
      full_name,
      email,
      district,
      block,
      ward,
      address,
      photo_url
    });

    // Get updated user data
    const result = await dbService.executeQuery(
      'SELECT citizen_id, full_name, email, phone, district, block, ward, address, photo_url FROM Citizens WHERE citizen_id = @citizen_id',
      { citizen_id }
    );

    const user = result.recordset[0];

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user
    });

  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({
      error: 'Update failed',
      message: error.message
    });
  }
});

// Change Password
router.put('/change-password', authMiddleware, [
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        details: errors.array()
      });
    }

    const { currentPassword, newPassword } = req.body;
    const citizen_id = req.user.citizen_id;

    // Get current user data
    const userResult = await dbService.executeQuery(
      'SELECT password_hash FROM Citizens WHERE citizen_id = @citizen_id',
      { citizen_id }
    );

    if (userResult.recordset.length === 0) {
      return res.status(404).json({
        error: 'User not found',
        message: 'User account not found'
      });
    }

    const user = userResult.recordset[0];

    // Verify current password
    const isValidPassword = await bcrypt.compare(currentPassword, user.password_hash);
    if (!isValidPassword) {
      return res.status(400).json({
        error: 'Invalid password',
        message: 'Current password is incorrect'
      });
    }

    // Hash new password
    const newPasswordHash = await bcrypt.hash(newPassword, 12);

    // Update password in database
    await dbService.executeQuery(
      'UPDATE Citizens SET password_hash = @password_hash, updated_at = GETDATE() WHERE citizen_id = @citizen_id',
      { 
        citizen_id,
        password_hash: newPasswordHash
      }
    );

    res.json({
      success: true,
      message: 'Password updated successfully'
    });

  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      error: 'Password change failed',
      message: error.message
    });
  }
});

module.exports = router;
