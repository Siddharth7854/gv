const fs = require('fs');
const path = require('path');

// Try to load SQL Server service first
let SQLServerService;
try {
  const { DatabaseService } = require('./database.js');
  SQLServerService = DatabaseService;
} catch (error) {
  console.log('⚠️ SQL Server service not available');
}

// Try to load SQLite service as fallback
let SQLiteService;
try {
  SQLiteService = require('./sqlite.js');
} catch (error) {
  console.log('⚠️ SQLite service not available');
}

class HybridDatabaseService {
  constructor() {
    this.activeService = null;
    this.serviceType = null;
  }

  async connect() {
    console.log('🔍 Attempting database connection...');
    
    // Try SQLite first for reliability
    if (SQLiteService) {
      try {
        console.log('📂 Trying SQLite...');
        this.activeService = new SQLiteService();
        await this.activeService.connect();
        this.serviceType = 'SQLite';
        console.log('✅ Connected to SQLite');
        return this.activeService;
      } catch (error) {
        console.log('❌ SQLite connection failed:', error.message);
        console.log('🔄 Falling back to SQL Server...');
      }
    }

    // Fallback to SQL Server
    if (SQLServerService) {
      try {
        console.log('📡 Trying SQL Server...');
        this.activeService = new SQLServerService();
        await this.activeService.connect();
        this.serviceType = 'SQL Server';
        console.log('✅ Connected to SQL Server');
        return this.activeService;
      } catch (error) {
        console.log('❌ SQL Server connection failed:', error.message);
        console.log('🔄 Falling back to JSON files...');
      }
    }

    // If both fail, create a simple file-based fallback
    console.log('🗃️ Using JSON file fallback...');
    this.activeService = new JSONFileService();
    await this.activeService.connect();
    this.serviceType = 'JSON File';
    console.log('✅ Using JSON file storage');
    
    return this.activeService;
  }

  getServiceInfo() {
    return {
      type: this.serviceType,
      isConnected: this.activeService !== null,
      timestamp: new Date().toISOString()
    };
  }

  async query(...args) {
    if (!this.activeService) {
      throw new Error('No database service available');
    }
    return await this.activeService.query(...args);
  }

  async close() {
    if (this.activeService) {
      await this.activeService.close();
    }
  }
}

// Simple JSON file service as last resort
class JSONFileService {
  constructor() {
    this.dataDir = path.join(__dirname, '../data');
    this.tables = {};
  }

  async connect() {
    // Ensure data directory exists
    if (!fs.existsSync(this.dataDir)) {
      fs.mkdirSync(this.dataDir, { recursive: true });
    }
    
    // Initialize basic tables
    this.tables = {
      users: this.loadTable('users'),
      grievances: this.loadTable('grievances'), 
      admins: this.loadTable('admins'),
      chat_messages: this.loadTable('chat_messages'),
      notifications: this.loadTable('notifications'),
      timeline: this.loadTable('timeline')
    };
    
    console.log('📁 JSON file storage initialized');
  }

  loadTable(tableName) {
    const filePath = path.join(this.dataDir, `${tableName}.json`);
    if (fs.existsSync(filePath)) {
      return JSON.parse(fs.readFileSync(filePath, 'utf8'));
    }
    return [];
  }

  saveTable(tableName, data) {
    const filePath = path.join(this.dataDir, `${tableName}.json`);
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
  }

  async query(sql, params = []) {
    // Very basic JSON query implementation
    // This is just a fallback for basic operations
    console.log('🗃️ JSON query:', sql.substring(0, 50) + '...');
    
    // Return empty result for now - this is just a fallback
    return { recordset: [] };
  }

  async close() {
    // Save all tables before closing
    for (const [tableName, data] of Object.entries(this.tables)) {
      this.saveTable(tableName, data);
    }
    console.log('💾 JSON files saved');
  }
}

module.exports = HybridDatabaseService;
