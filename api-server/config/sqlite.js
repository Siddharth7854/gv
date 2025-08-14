const sqlite3 = require('sqlite3');
const { open } = require('sqlite');
const path = require('path');

class SQLiteService {
  constructor() {
    this.db = null;
    this.dbPath = path.join(__dirname, '../data/grievance.db');
  }

  async connect() {
    try {
      // Ensure data directory exists
      const fs = require('fs');
      const dataDir = path.dirname(this.dbPath);
      if (!fs.existsSync(dataDir)) {
        fs.mkdirSync(dataDir, { recursive: true });
      }

      console.log('📂 Connecting to SQLite database...');
      this.db = await open({
        filename: this.dbPath,
        driver: sqlite3.Database
      });
      
      console.log('✅ Connected to SQLite database');
      await this.initializeDatabase();
      return this.db;
      
    } catch (error) {
      console.error('❌ SQLite connection failed:', error);
      throw error;
    }
  }

  async initializeDatabase() {
    console.log('🛠️ Initializing SQLite database...');
    
    // Enable foreign keys
    await this.db.exec('PRAGMA foreign_keys = ON');
    
    await this.createAllTables();
    console.log('✅ SQLite database initialized');
  }

  async createAllTables() {
    console.log('📋 Creating SQLite tables...');

    try {
      // Users Table
      await this.db.exec(`
      CREATE TABLE IF NOT EXISTS users (
        userId TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        fullName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'citizen',
        isActive INTEGER DEFAULT 1,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        photoUrl TEXT,
        fcmToken TEXT
      )
    `);

    // Grievances Table
    await this.db.exec(`
      CREATE TABLE IF NOT EXISTS grievances (
        grievanceId TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        priority TEXT DEFAULT 'medium',
        status TEXT DEFAULT 'pending',
        assignedTo TEXT,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        resolvedAt DATETIME,
        photoUrl TEXT,
        adminComments TEXT,
        FOREIGN KEY (userId) REFERENCES users(userId)
      )
    `);

    // Admins Table
    await this.db.exec(`
      CREATE TABLE IF NOT EXISTS admins (
        adminId TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        fullName TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'admin',
        department TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        lastLogin DATETIME,
        fcmToken TEXT
      )
    `);

    // Chat Messages Table
    await this.db.exec(`
      CREATE TABLE IF NOT EXISTS chat_messages (
        messageId TEXT PRIMARY KEY,
        grievanceId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        senderType TEXT NOT NULL,
        message TEXT NOT NULL,
        messageType TEXT DEFAULT 'text',
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        isRead INTEGER DEFAULT 0,
        FOREIGN KEY (grievanceId) REFERENCES grievances(grievanceId)
      )
    `);

    // Notifications Table
    await this.db.exec(`
      CREATE TABLE IF NOT EXISTS notifications (
        notificationId TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        data TEXT,
        FOREIGN KEY (userId) REFERENCES users(userId)
      )
    `);

    // Timeline Table
    await this.db.exec(`
      CREATE TABLE IF NOT EXISTS timeline (
        timelineId TEXT PRIMARY KEY,
        grievanceId TEXT NOT NULL,
        action TEXT NOT NULL,
        description TEXT NOT NULL,
        performedBy TEXT NOT NULL,
        performedByType TEXT NOT NULL,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        metadata TEXT,
        FOREIGN KEY (grievanceId) REFERENCES grievances(grievanceId)
      )
    `);

    console.log('✅ All SQLite tables created successfully');
    } catch (error) {
      console.error('❌ Error creating SQLite tables:', error);
      throw error;
    }
  }

  async query(sql, params = []) {
    if (!this.db) {
      throw new Error('Database not connected');
    }
    return await this.db.all(sql, params);
  }

  async run(sql, params = []) {
    if (!this.db) {
      throw new Error('Database not connected');
    }
    return await this.db.run(sql, params);
  }

  async get(sql, params = []) {
    if (!this.db) {
      throw new Error('Database not connected');
    }
    return await this.db.get(sql, params);
  }

  async close() {
    if (this.db) {
      await this.db.close();
      console.log('✅ SQLite connection closed');
    }
  }
}

module.exports = SQLiteService;
