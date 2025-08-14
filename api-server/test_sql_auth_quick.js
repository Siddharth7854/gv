const sql = require('mssql');

// Quick SQL Authentication test
const sqlAuthConfig = {
  server: 'DESKTOP-E2H6BA3\\SQLEXPRESS',
  database: 'master',
  user: 'sa',
  password: 'Sid91221',
  options: {
    encrypt: false,
    trustServerCertificate: true,
    enableArithAbort: true,
  },
  connectionTimeout: 15000, // 15 seconds
  requestTimeout: 15000,
};

async function quickSQLAuthTest() {
  console.log('🔍 Quick SQL Authentication Test...');
  console.log('Server: DESKTOP-E2H6BA3\\SQLEXPRESS');
  console.log('User: sa');
  console.log('');
  
  try {
    console.log('📡 Connecting with SQL Authentication...');
    const pool = await sql.connect(sqlAuthConfig);
    console.log('✅ SQL Authentication SUCCESS!');
    
    // Test basic operations
    const result = await pool.request().query(`
      SELECT 
        @@VERSION as version,
        @@SERVERNAME as serverName,
        DB_NAME() as currentDB,
        SYSTEM_USER as loginUser
    `);
    
    const row = result.recordset[0];
    console.log('📋 Connection Details:');
    console.log('   Server:', row.serverName);
    console.log('   Database:', row.currentDB);
    console.log('   Login User:', row.loginUser);
    console.log('   Version:', row.version.substring(0, 60) + '...');
    
    // Check if target database exists
    console.log('\n🗃️ Checking for GrievanceManagementDB...');
    const dbCheck = await pool.request().query(`
      SELECT COUNT(*) as dbExists 
      FROM sys.databases 
      WHERE name = 'GrievanceManagementDB'
    `);
    
    if (dbCheck.recordset[0].dbExists > 0) {
      console.log('✅ GrievanceManagementDB exists');
    } else {
      console.log('ℹ️ GrievanceManagementDB will be created');
      
      // Create database
      console.log('🛠️ Creating GrievanceManagementDB...');
      await pool.request().query('CREATE DATABASE GrievanceManagementDB');
      console.log('✅ Database created successfully!');
    }
    
    await pool.close();
    
    console.log('\n🎯 SUCCESS! Use this configuration:');
    console.log('=' * 50);
    console.log(JSON.stringify(sqlAuthConfig, null, 2));
    console.log('=' * 50);
    
    // Update the main database config
    await updateDatabaseConfig(sqlAuthConfig);
    
  } catch (error) {
    console.log('❌ SQL Authentication failed:', error.message);
    
    if (error.message.includes('Login failed')) {
      console.log('\n💡 SQL Server Mixed Mode Authentication might be disabled');
      console.log('   Enable it in SQL Server Management Studio or');
      console.log('   Use Windows Authentication instead');
    }
  }
}

async function updateDatabaseConfig(workingConfig) {
  const fs = require('fs').promises;
  
  try {
    console.log('\n🔄 Updating database.js with working configuration...');
    
    const configContent = `const sql = require('mssql');

const config = {
  server: '${workingConfig.server}',
  database: '${workingConfig.database}',
  user: '${workingConfig.user}',
  password: '${workingConfig.password}',
  options: {
    encrypt: false,
    trustServerCertificate: true,
    enableArithAbort: true,
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
  connectionTimeout: 30000,
  requestTimeout: 30000,
};

console.log('Database config:', {
  server: config.server,
  database: config.database,
  user: config.user,
  port: config.port
});

// Rest of your existing DatabaseService class...
module.exports = config;
`;
    
    await fs.writeFile('./config/database_working.js', configContent);
    console.log('✅ Working config saved to database_working.js');
    
  } catch (error) {
    console.log('⚠️ Could not update config file:', error.message);
  }
}

quickSQLAuthTest().catch(console.error);
