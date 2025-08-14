const sql = require('mssql');

// Test database connection with your server
const testConfig = {
  server: 'DESKTOP-E2H6BA3\\SQLEXPRESS',
  database: 'master', // Connect to master first
  
  // Use Windows Authentication
  authentication: {
    type: 'default'
  },
  
  options: {
    encrypt: false,
    trustServerCertificate: true,
    enableArithAbort: true,
    integratedSecurity: true,
  },
  connectionTimeout: 60000, // Increased timeout
  requestTimeout: 30000,
};

async function testConnection() {
  console.log('🔍 Testing SQL Server connection...');
  console.log('Server:', testConfig.server);
  console.log('Authentication: Windows Authentication');
  console.log('');

  try {
    // Test connection to master database
    console.log('📡 Connecting to master database...');
    const pool = await sql.connect(testConfig);
    console.log('✅ Connected to SQL Server successfully!');
    
    // Check if our database exists
    console.log('🔍 Checking for GrievanceManagementDB...');
    const result = await pool.request().query(`
      SELECT name FROM sys.databases WHERE name = 'GrievanceManagementDB'
    `);
    
    if (result.recordset.length > 0) {
      console.log('✅ GrievanceManagementDB database exists');
    } else {
      console.log('⚠️ GrievanceManagementDB database not found');
      console.log('💡 It will be created automatically when you start the server');
    }
    
    // List all databases
    console.log('');
    console.log('📋 Available databases:');
    const dbList = await pool.request().query('SELECT name FROM sys.databases ORDER BY name');
    dbList.recordset.forEach(db => {
      console.log(`   - ${db.name}`);
    });
    
    await pool.close();
    
    console.log('');
    console.log('🎉 Connection test successful!');
    console.log('💡 You can now start the server with: npm start');
    
  } catch (error) {
    console.error('❌ Connection test failed:');
    console.error('Error:', error.message);
    console.log('');
    console.log('🔧 Troubleshooting:');
    console.log('1. Check if SQL Server is running');
    console.log('2. Verify server name: DESKTOP-E2H6BA3\\SQLEXPRESS');
    console.log('3. Check if SQL Server Authentication is enabled');
    console.log('4. Verify sa account is enabled and password is correct');
    console.log('5. Check Windows Firewall settings');
  }
}

testConnection();
