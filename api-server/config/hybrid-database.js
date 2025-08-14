const fs = require('fs');
const path = require('path');

// Try to load SQL Server service first (only when needed)
let SQLServerService;
function loadSQLServerService() {
  if (!SQLServerService) {
    try {
      const { DatabaseService } = require('./database.js');
      SQLServerService = DatabaseService;
    } catch (error) {
      console.log('⚠️ SQL Server service not available:', error.message);
    }
  }
  return SQLServerService;
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
    this.sqlServerAttempted = false;
  }

  async connect() {
    console.log('🔍 Attempting database connection...');
    
    // Try SQL Server first with timeout handling (only once)
    const SQLServerServiceClass = loadSQLServerService();
    if (SQLServerServiceClass && !this.sqlServerAttempted) {
      try {
        console.log('🔗 Trying SQL Server...');
        this.sqlServerAttempted = true;
        
        // Create connection with timeout to prevent hanging
        const connectPromise = new Promise(async (resolve, reject) => {
          try {
            this.activeService = new SQLServerServiceClass();
            await this.activeService.connect();
            resolve();
          } catch (error) {
            reject(error);
          }
        });
        
        // Race connection vs timeout (10 seconds max)
        await Promise.race([
          connectPromise,
          new Promise((_, reject) => 
            setTimeout(() => reject(new Error('SQL Server connection timeout')), 10000)
          )
        ]);
        
        this.serviceType = 'SQL Server';
        console.log('✅ Connected to SQL Server');
        return this.activeService;
        
      } catch (error) {
        console.log('❌ SQL Server connection failed:', error.message);
        console.log('🔄 Falling back to SQLite...');
        this.activeService = null;
      }
    }

    // Fallback to SQLite (most reliable)
    if (SQLiteService) {
      try {
        console.log('📂 Connecting to SQLite database...');
        this.activeService = new SQLiteService();
        await this.activeService.connect();
        this.serviceType = 'SQLite';
        console.log('✅ Connected to SQLite');
        return this.activeService;
      } catch (error) {
        console.log('❌ SQLite connection failed:', error.message);
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

  // Method to retry SQL Server connection later
  async retrySQLServer() {
    if (this.serviceType !== 'SQL Server') {
      this.sqlServerAttempted = false;
      return await this.connect();
    }
    return this.activeService;
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
