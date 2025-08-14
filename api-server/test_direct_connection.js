const sql = require('mssql');

// Direct connection test with port
const testConfig = {
  server: 'localhost,1433',
  database: 'master',
  
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
  connectionTimeout: 30000,
  requestTimeout: 30000,
};

async function testDirectConnection() {
  console.log('🔍 Testing direct SQL Server connection...');
  console.log('Server: localhost,1433');
  console.log('Authentication: Windows Authentication');
  console.log('');
  
  try {
    console.log('📡 Connecting to SQL Server...');
    const pool = await sql.connect(testConfig);
    console.log('✅ Connection established successfully!');
    
    // Test basic query
    console.log('🔍 Testing basic query...');
    const result = await pool.request().query('SELECT @@VERSION as version, GETDATE() as currentTime');
    
    console.log('📋 Query Results:');
    console.log('   Version:', result.recordset[0].version.substring(0, 80) + '...');
    console.log('   Current Time:', result.recordset[0].currentTime);
    
    // List databases
    console.log('🗃️ Available databases:');
    const dbResult = await pool.request().query('SELECT name FROM sys.databases WHERE database_id > 4');
    dbResult.recordset.forEach(db => {
      console.log('   -', db.name);
    });
    
    await pool.close();
    console.log('🎯 SUCCESS: Database connection working!');
    
  } catch (error) {
    console.log('❌ Connection failed:', error.message);
    console.log('');
    console.log('💡 Troubleshooting steps:');
    console.log('1. Check if SQL Server Express service is running');
    console.log('2. Enable TCP/IP protocol in SQL Server Configuration Manager');
    console.log('3. Make sure port 1433 is open');
    console.log('4. Check Windows Firewall settings');
  }
}

testDirectConnection().catch(console.error);
