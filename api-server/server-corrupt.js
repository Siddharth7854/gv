const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit'    app.listen(PORT, () => {
      console.log('🚀 Grievance Management API Server Started!');
      console.log('='.repeat(50));
      console.log(`🌐 Server URL: http://localhost:${PORT}`);
      console.log(`📊 Health Check: http://localhost:${PORT}/api/health`);
      console.log(`👤 Admin Portal: http://localhost:${PORT}/api/admin/login`);
      console.log(`📱 Mobile API: http://localhost:${PORT}/api/auth/login`);
      console.log('='.repeat(50));
      console.log('🎉 Server is ready to accept requests!');
      console.log('💡 Database tables will be created automatically on first use.');
    });('dotenv').config();

const authRoutes = require('./routes/auth');
const grievanceRoutes = require('./routes/grievances');
const categoryRoutes = require('./routes/categories');
const uploadRoutes = require('./routes/upload');
const dashboardRoutes = require('./routes/dashboard');
const adminRoutes = require('./routes/admin');
const notificationRoutes = require('./routes/notifications');
const chatRoutes = require('./routes/chat');
const debugRoutes = require('./routes/debug');
const HybridDatabaseService = require('./config/hybrid-database');

const app = express();
const PORT = process.env.PORT || 5000;

// Initialize hybrid database service
const dbService = new HybridDatabaseService();

// Database initialization check
async function initializeServer() {
  try {
    console.log('🔧 Initializing Grievance Management System...');
    console.log('='.repeat(50));
    
    // Connect to database (will auto-fallback)
    const db = await dbService.connect();
    const serviceInfo = dbService.getServiceInfo();
    
    console.log('✅ Database Connection Established!');
    console.log('📋 System Configuration:');
    console.log(`   Database Type: ${serviceInfo.type}`);
    console.log(`   Server: DESKTOP-E2H6BA3\\SQLEXPRESS`);
    console.log(`   Target Database: GrievanceManagementDB`);
    console.log(`   API Port: ${PORT}`);
    console.log(`   Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`   Initialized: ${serviceInfo.timestamp}`);
    console.log('='.repeat(50));
    
    // Store database service for routes
    app.set('dbService', dbService);
    
  } catch (error) {
    console.error('❌ Failed to initialize server:', error);
    console.error('💡 Falling back to JSON file storage...');
    // Don't exit, let it try JSON fallback
    app.set('dbService', dbService);
  }
}

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
});
app.use('/api/', limiter);

// CORS configuration - Allow all origins for development
const corsOptions = {
  origin: true, // Allow all origins for development
  credentials: true,
  optionsSuccessStatus: 200,
};
app.use(cors(corsOptions));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static files
app.use('/uploads', express.static('uploads'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/grievances', grievanceRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin/chat', chatRoutes);

// Debug route for admin
app.get('/api/debug/admin', async (req, res) => {
  try {
    const result = await dbService.executeQuery('SELECT * FROM Admins');
    res.json({ admins: result.recordset });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV,
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      error: 'Validation Error',
      message: err.message,
      details: err.details,
    });
  }
  
  if (err.name === 'UnauthorizedError') {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid authentication credentials',
    });
  }
  
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`,
  });
});

// Start server
async function startServer() {
  try {
    // Initialize database and auto-create tables
    await initializeServer();
    
    app.listen(PORT, () => {
      console.log('🚀 Grievance Management API Server Started!');
      console.log('=' * 50);
      console.log(`🌐 Server URL: http://localhost:${PORT}`);
      console.log(`� Health Check: http://localhost:${PORT}/api/health`);
      console.log(`👤 Admin Portal: http://localhost:${PORT}/api/admin/login`);
      console.log(`📱 Mobile API: http://localhost:${PORT}/api/auth/login`);
      console.log('=' * 50);
      console.log('🎉 Server is ready to accept requests!');
      console.log('💡 Database tables will be created automatically on first use.');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;
