const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Only SQLite - no SQL Server imports
const SQLiteService = require('./config/sqlite');

const authRoutes = require('./routes/auth');
const grievanceRoutes = require('./routes/grievances');
const categoryRoutes = require('./routes/categories');
const uploadRoutes = require('./routes/upload');
const dashboardRoutes = require('./routes/dashboard');
const adminRoutes = require('./routes/admin');
const notificationRoutes = require('./routes/notifications');
const chatRoutes = require('./routes/chat');
const debugRoutes = require('./routes/debug');

const app = express();
const PORT = process.env.PORT || 5000;

// Initialize SQLite database service
const dbService = new SQLiteService();

// Database initialization check
async function initializeServer() {
  try {
    console.log('🔧 Initializing Grievance Management System...');
    console.log('='.repeat(50));
    
    // Connect to SQLite database only
    console.log('📂 Connecting to SQLite database...');
    await dbService.connect();
    
    console.log('✅ Database Connection Established!');
    console.log('📋 System Configuration:');
    console.log(`   Database Type: SQLite`);
    console.log(`   Database File: ${dbService.dbPath}`);
    console.log(`   API Port: ${PORT}`);
    console.log(`   Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`   Initialized: ${new Date().toISOString()}`);
    console.log('='.repeat(50));
    
    // Store database service for routes
    app.set('dbService', dbService);
    
  } catch (error) {
    console.error('❌ Failed to initialize server:', error);
    console.error('💡 Please check your SQLite configuration and try again.');
    process.exit(1);
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
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};
app.use(cors(corsOptions));

// Body parsing middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Static files
app.use('/uploads', express.static('uploads'));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    database: {
      type: 'SQLite',
      isConnected: dbService.db !== null,
      file: dbService.dbPath
    },
    port: PORT
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/grievances', grievanceRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/debug', debugRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Global error handler:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl
  });
});

// Start server function
async function startServer() {
  try {
    // Initialize database first
    await initializeServer();
    
    // Start HTTP server
    app.listen(PORT, () => {
      console.log('🚀 Grievance Management API Server Started!');
      console.log('='.repeat(50));
      console.log(`🌐 Server URL: http://localhost:${PORT}`);
      console.log(`📊 Health Check: http://localhost:${PORT}/api/health`);
      console.log(`👤 Admin Portal: http://localhost:${PORT}/api/admin/login`);
      console.log(`📱 Mobile API: http://localhost:${PORT}/api/auth/login`);
      console.log('='.repeat(50));
      console.log('🎉 Server is ready to accept requests!');
      console.log('💡 Using SQLite database for reliable local storage.');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;
