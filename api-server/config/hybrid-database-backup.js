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
        console.log('� Trying SQLite...');
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
        console.log('� Trying SQL Server...');
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
        this.serviceType = 'SQLite';
        console.log('✅ Connected to SQLite');
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

    // Load existing data
    await this.loadTables();
    console.log('📁 JSON file storage initialized');
  }

  async loadTables() {
    const tableFiles = ['users.json', 'grievances.json', 'admins.json', 'notifications.json'];
    
    for (const file of tableFiles) {
      const filePath = path.join(this.dataDir, file);
      const tableName = path.basename(file, '.json');
      
      try {
        if (fs.existsSync(filePath)) {
          const data = fs.readFileSync(filePath, 'utf8');
          this.tables[tableName] = JSON.parse(data);
        } else {
          this.tables[tableName] = [];
        }
      } catch (error) {
        console.log(`⚠️ Error loading ${file}:`, error.message);
        this.tables[tableName] = [];
      }
    }
  }

  async saveTable(tableName) {
    const filePath = path.join(this.dataDir, `${tableName}.json`);
    const data = JSON.stringify(this.tables[tableName] || [], null, 2);
    fs.writeFileSync(filePath, data, 'utf8');
  }

  async query(sql, params = []) {
    // Simple query implementation for basic operations
    // This is a minimal implementation for demo purposes
    console.log('📝 JSON File Query:', sql);
    return [];
  }

  async close() {
    // Save all tables before closing
    for (const tableName of Object.keys(this.tables)) {
      await this.saveTable(tableName);
    }
    console.log('💾 JSON file data saved');
  }
}

module.exports = HybridDatabaseService;
