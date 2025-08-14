const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Only SQLite - no SQL Server imports
const SQLiteService = require('./config/sqlite');

// Import routes
const authRoutes = require('./routes/auth-fixed');
const adminRoutes = require('./routes/admin');

const app = express();
const PORT = process.env.PORT || 5000;

// Initialize SQLite database service
const dbService = new SQLiteService();

// Database initialization
async function initializeServer() {
  try {
    console.log('🔧 Initializing Grievance Management System (SQLite Only)...');
    console.log('='.repeat(60));
    
    // Connect to SQLite database only
    console.log('📂 Connecting to SQLite database...');
    await dbService.connect();
    
    console.log('✅ Database Connection Established!');
    console.log('📋 System Configuration:');
    console.log(`   Database Type: SQLite Only`);
    console.log(`   Database File: ${dbService.dbPath}`);
    console.log(`   API Port: ${PORT}`);
    console.log(`   Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`   Initialized: ${new Date().toISOString()}`);
    console.log('='.repeat(60));
    
    // Store database service for routes
    app.set('dbService', dbService);
    
    return true;
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

// CORS configuration
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
    port: PORT,
    routes: {
      auth: 'enabled',
      admin: 'enabled',
      grievances: 'disabled',
      chat: 'disabled'
    }
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);

// Test endpoint
app.get('/api/test', (req, res) => {
  res.json({
    message: 'API server is working!',
    timestamp: new Date().toISOString(),
    database: 'SQLite',
    status: 'healthy'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ Server Error:', err);
  
  if (res.headersSent) {
    return next(err);
  }
  
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl,
    timestamp: new Date().toISOString()
  });
});

// Initialize and start server
async function startServer() {
  try {
    // Initialize database
    await initializeServer();
    
    // Start server
    const server = app.listen(PORT, () => {
      console.log('🚀 Grievance Management API Server Started!');
      console.log('='.repeat(60));
      console.log(`🌐 Server URL: http://localhost:${PORT}`);
      console.log(`📊 Health Check: http://localhost:${PORT}/api/health`);
      console.log(`🧪 Test Endpoint: http://localhost:${PORT}/api/test`);
      console.log(`👤 Auth Register: http://localhost:${PORT}/api/auth/register`);
      console.log(`📱 Auth Login: http://localhost:${PORT}/api/auth/login`);
      console.log(`🔑 Admin Login: http://localhost:${PORT}/api/admin/admin-login`);
      console.log('='.repeat(60));
      console.log('🎉 Server is ready to accept requests!');
      console.log('💡 Using SQLite database for reliable local storage.');
      console.log('✅ No SQL Server dependencies - fully self-contained!');
    });

    // Graceful shutdown
    process.on('SIGTERM', () => {
      console.log('🔄 SIGTERM received, shutting down gracefully...');
      server.close(() => {
        console.log('✅ Server closed successfully');
        process.exit(0);
      });
    });

    process.on('SIGINT', () => {
      console.log('🔄 SIGINT received, shutting down gracefully...');
      server.close(() => {
        console.log('✅ Server closed successfully');
        process.exit(0);
      });
    });

  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  // Close server gracefully
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  process.exit(1);
});

// Start the server
startServer();
