const sql = require('mssql');

const config = {
  // Use environment variable for server name
  server: process.env.DB_SERVER || 'DESKTOP-E2H6BA3\\SQLEXPRESS',
  database: process.env.DB_DATABASE || 'GrievanceManagementDB',
  
  // Windows Authentication (matching your SSMS connection)
  authentication: {
    type: 'default'
  },
  
  options: {
    encrypt: false, // Set to true if using Azure SQL
    trustServerCertificate: true, // Set to false in production
    enableArithAbort: true,
    integratedSecurity: true, // Enable Windows Authentication
    instanceName: 'SQLEXPRESS', // Specify instance name
    useUTC: false,
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
  connectionTimeout: 30000,
  requestTimeout: 30000,
};

// Only log config when explicitly enabled to avoid noise during SQLite-only runs
if (process.env.ENABLE_SQL_SERVER === 'true') {
  console.log('Database config:', {
    server: config.server,
    database: config.database,
    authentication: 'Windows Authentication (Integrated Security)',
    port: config.port
  });
}

class DatabaseService {
  constructor() {
    this.pool = null;
  }

  async connect() {
    try {
      if (process.env.ENABLE_SQL_SERVER !== 'true') {
        throw new Error('SQL Server connection disabled. Set ENABLE_SQL_SERVER=true to enable.');
      }
      console.log('Attempting to connect with config:', config);
      this.pool = await sql.connect(config);
      console.log('✅ Connected to SQL Server database');
      
      // Auto-create database and tables on first connection
      await this.initializeDatabase();
      
      return this.pool;
    } catch (error) {
      console.error('❌ Database connection failed:', error);
      throw error;
    }
  }

  async initializeDatabase() {
    try {
      console.log('🔧 Initializing database and tables...');
      
      // Check if database exists, create if not
      await this.createDatabaseIfNotExists();
      
      // Create all required tables
      await this.createAllTables();
      
      console.log('✅ Database initialization completed');
    } catch (error) {
      console.error('❌ Database initialization failed:', error);
      throw error;
    }
  }

  async createDatabaseIfNotExists() {
    try {
      // Connect to master database to check/create our database
      const masterConfig = { ...config, database: 'master' };
      const masterPool = await sql.connect(masterConfig);
      
      const checkDbQuery = `
        SELECT database_id 
        FROM sys.databases 
        WHERE name = '${config.database}'
      `;
      
      const result = await masterPool.request().query(checkDbQuery);
      
      if (result.recordset.length === 0) {
        console.log(`📁 Creating database: ${config.database}`);
        
        const createDbQuery = `
          CREATE DATABASE [${config.database}]
          COLLATE SQL_Latin1_General_CP1_CI_AS
        `;
        
        await masterPool.request().query(createDbQuery);
        console.log(`✅ Database created: ${config.database}`);
      } else {
        console.log(`✅ Database already exists: ${config.database}`);
      }
      
      await masterPool.close();
    } catch (error) {
      console.error('❌ Error creating database:', error);
      throw error;
    }
  }

  async createAllTables() {
    try {
      if (!this.pool) {
        throw new Error('Database connection not established');
      }

      console.log('📋 Creating tables...');

      // Users Table
      await this.createUsersTable();
      
      // Grievances Table
      await this.createGrievancesTable();
      
      // Admins Table
      await this.createAdminsTable();
      
      // Chat Messages Table
      await this.createChatMessagesTable();
      
      // Notifications Table (FCM)
      await this.createNotificationsTable();
      
      // Timeline Table
      await this.createTimelineTable();
      
      console.log('✅ All tables created successfully');
    } catch (error) {
      console.error('❌ Error creating tables:', error);
      throw error;
    }
  }

  async createUsersTable() {
    const createUsersQuery = `
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='users' AND xtype='U')
      CREATE TABLE users (
        userId NVARCHAR(50) PRIMARY KEY,
        email NVARCHAR(255) UNIQUE NOT NULL,
        fullName NVARCHAR(255) NOT NULL,
        phoneNumber NVARCHAR(20) NOT NULL,
        password NVARCHAR(255) NOT NULL,
        role NVARCHAR(50) DEFAULT 'citizen',
        isActive BIT DEFAULT 1,
        createdAt DATETIME2 DEFAULT GETDATE(),
        updatedAt DATETIME2 DEFAULT GETDATE(),
        photoUrl NVARCHAR(500),
        fcmToken NVARCHAR(500),
        lastLoginAt DATETIME2
      )
    `;
    
    await this.pool.request().query(createUsersQuery);
    console.log('✅ Users table created/verified');
  }

  async createGrievancesTable() {
    const createGrievancesQuery = `
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='grievances' AND xtype='U')
      CREATE TABLE grievances (
        grievanceId NVARCHAR(50) PRIMARY KEY,
        userId NVARCHAR(50) NOT NULL,
        title NVARCHAR(255) NOT NULL,
        description NTEXT NOT NULL,
        category NVARCHAR(100) NOT NULL,
        priority NVARCHAR(20) DEFAULT 'medium',
        status NVARCHAR(50) DEFAULT 'pending',
        attachments NTEXT,
        imageUrls NTEXT,
        location NVARCHAR(255),
        createdAt DATETIME2 DEFAULT GETDATE(),
        updatedAt DATETIME2 DEFAULT GETDATE(),
        assignedTo NVARCHAR(50),
        resolvedAt DATETIME2,
        adminComments NTEXT,
        FOREIGN KEY (userId) REFERENCES users(userId)
      )
    `;
    
    await this.pool.request().query(createGrievancesQuery);
    console.log('✅ Grievances table created/verified');
  }

  async createAdminsTable() {
    const createAdminsQuery = `
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='admins' AND xtype='U')
      CREATE TABLE admins (
        adminId NVARCHAR(50) PRIMARY KEY,
        username NVARCHAR(100) UNIQUE NOT NULL,
        email NVARCHAR(255) UNIQUE NOT NULL,
        fullName NVARCHAR(255) NOT NULL,
        password NVARCHAR(255) NOT NULL,
        role NVARCHAR(50) DEFAULT 'admin',
        permissions NTEXT,
        isActive BIT DEFAULT 1,
        createdAt DATETIME2 DEFAULT GETDATE(),
        updatedAt DATETIME2 DEFAULT GETDATE(),
        lastLoginAt DATETIME2,
        fcmToken NVARCHAR(500)
      )
    `;
    
    await this.pool.request().query(createAdminsQuery);
    console.log('✅ Admins table created/verified');
    
    // Insert default admin if not exists
    const checkAdminQuery = `SELECT COUNT(*) as count FROM admins WHERE username = 'admin'`;
    const adminExists = await this.pool.request().query(checkAdminQuery);
    
    if (adminExists.recordset[0].count === 0) {
      const insertAdminQuery = `
        INSERT INTO admins (adminId, username, email, fullName, password, role, isActive)
        VALUES ('admin001', 'admin', 'admin@gov.in', 'System Administrator', 'admin123', 'superadmin', 1)
      `;
      await this.pool.request().query(insertAdminQuery);
      console.log('✅ Default admin user created (username: admin, password: admin123)');
    }
  }

  async createChatMessagesTable() {
    const createChatQuery = `
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='chat_messages' AND xtype='U')
      CREATE TABLE chat_messages (
        messageId NVARCHAR(50) PRIMARY KEY,
        grievanceId NVARCHAR(50) NOT NULL,
        senderId NVARCHAR(50) NOT NULL,
        senderType NVARCHAR(20) NOT NULL, -- 'user' or 'admin'
        message NTEXT NOT NULL,
        attachments NTEXT,
        timestamp DATETIME2 DEFAULT GETDATE(),
        isRead BIT DEFAULT 0,
        FOREIGN KEY (grievanceId) REFERENCES grievances(grievanceId)
      )
    `;
    
    await this.pool.request().query(createChatQuery);
    console.log('✅ Chat messages table created/verified');
  }

  async createNotificationsTable() {
    const createNotificationsQuery = `
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='notifications' AND xtype='U')
      CREATE TABLE notifications (
        notificationId NVARCHAR(50) PRIMARY KEY,
        userId NVARCHAR(50),
        adminId NVARCHAR(50),
        title NVARCHAR(255) NOT NULL,
        body NTEXT NOT NULL,
        type NVARCHAR(50) NOT NULL, -- 'fcm', 'in_app', 'email'
        data NTEXT, -- JSON data
        fcmToken NVARCHAR(500),
        status NVARCHAR(20) DEFAULT 'pending', -- 'pending', 'sent', 'failed'
        sentAt DATETIME2,
        createdAt DATETIME2 DEFAULT GETDATE(),
        grievanceId NVARCHAR(50),
        FOREIGN KEY (grievanceId) REFERENCES grievances(grievanceId)
      )
    `;
    
    await this.pool.request().query(createNotificationsQuery);
    console.log('✅ Notifications table created/verified');
  }

  async createTimelineTable() {
    const createTimelineQuery = `
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='grievance_timeline' AND xtype='U')
      CREATE TABLE grievance_timeline (
        timelineId NVARCHAR(50) PRIMARY KEY,
        grievanceId NVARCHAR(50) NOT NULL,
        action NVARCHAR(255) NOT NULL,
        description NTEXT,
        performedBy NVARCHAR(50) NOT NULL,
        performedByType NVARCHAR(20) NOT NULL, -- 'user' or 'admin'
        timestamp DATETIME2 DEFAULT GETDATE(),
        status NVARCHAR(50),
        metadata NTEXT, -- JSON for additional data
        FOREIGN KEY (grievanceId) REFERENCES grievances(grievanceId)
      )
    `;
    
    await this.pool.request().query(createTimelineQuery);
    console.log('✅ Grievance timeline table created/verified');
  }

  async disconnect() {
    try {
      if (this.pool) {
        await this.pool.close();
        console.log('🔌 Disconnected from SQL Server database');
      }
    } catch (error) {
      console.error('❌ Error disconnecting from database:', error);
    }
  }

  getPool() {
    if (!this.pool) {
      throw new Error('Database not connected. Call connect() first.');
    }
    return this.pool;
  }

  async executeQuery(query, params = {}) {
    try {
      const request = this.pool.request();
      
      // Add parameters to request
      Object.keys(params).forEach(key => {
        request.input(key, params[key]);
      });

      const result = await request.query(query);
      return result;
    } catch (error) {
      console.error('Query execution error:', error);
      throw error;
    }
  }

  async executeStoredProcedure(procedureName, params = {}) {
    try {
      const request = this.pool.request();
      
      // Add parameters to request
      Object.keys(params).forEach(key => {
        request.input(key, params[key]);
      });

      const result = await request.execute(procedureName);
      return result;
    } catch (error) {
      console.error('Stored procedure execution error:', error);
      throw error;
    }
  }

  async transaction(callback) {
    const transaction = new sql.Transaction(this.pool);
    
    try {
      await transaction.begin();
      const request = new sql.Request(transaction);
      const result = await callback(request);
      await transaction.commit();
      return result;
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }
}

// Export the class and config, without auto-connecting on import
module.exports = {
  DatabaseService,
  config,
  sql
};

// For backward compatibility with existing code, create a minimal shim that won't auto-connect
// but will provide the expected API methods that throw informative errors
const dbServiceShim = {
  connect: async () => {
    throw new Error('SQL Server is disabled. Set ENABLE_SQL_SERVER=true to enable.');
  },
  executeQuery: async () => {
    throw new Error('SQL Server is disabled. Use SQLite service instead via req.app.get("dbService")');
  },
  getPool: () => {
    throw new Error('SQL Server is disabled. Use SQLite service instead via req.app.get("dbService")');
  },
  disconnect: async () => {
    // No-op for safety
  }
};

// Export dbServiceShim as default for backward compatibility
module.exports = Object.assign(module.exports, dbServiceShim);
