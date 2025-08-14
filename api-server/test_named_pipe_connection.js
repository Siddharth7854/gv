const sql = require('mssql');

// Named Pipe connection test
const testConfig = {
  server: '.\\SQLEXPRESS', // Local named instance
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
    useUTC: false,
  },
  connectionTimeout: 30000,
  requestTimeout: 30000,
};

async function testNamedPipeConnection() {
  console.log('🔍 Testing SQL Server connection with Named Pipes...');
  console.log('Server: .\\SQLEXPRESS');
  console.log('Authentication: Windows Authentication');
  console.log('');
  
  try {
    console.log('📡 Connecting to SQL Server...');
    const pool = await sql.connect(testConfig);
    console.log('✅ Connection established successfully!');
    
    // Test basic query
    console.log('🔍 Testing basic query...');
    const result = await pool.request().query('SELECT @@VERSION as version, @@SERVERNAME as serverName, GETDATE() as currentTime');
    
    console.log('📋 Connection Results:');
    console.log('   Server Name:', result.recordset[0].serverName);
    console.log('   Version:', result.recordset[0].version.substring(0, 80) + '...');
    console.log('   Current Time:', result.recordset[0].currentTime);
    
    // Check if our target database exists
    console.log('🗃️ Checking for GrievanceManagementDB...');
    const dbCheck = await pool.request().query(`
      SELECT name FROM sys.databases 
      WHERE name = 'GrievanceManagementDB'
    `);
    
    if (dbCheck.recordset.length > 0) {
      console.log('✅ GrievanceManagementDB already exists!');
    } else {
      console.log('ℹ️ GrievanceManagementDB does not exist - will be created automatically');
    }
    
    // List all databases
    console.log('🗃️ Available databases:');
    const dbResult = await pool.request().query('SELECT name FROM sys.databases ORDER BY name');
    dbResult.recordset.forEach(db => {
      console.log('   -', db.name);
    });
    
    await pool.close();
    console.log('');
    console.log('🎯 SUCCESS: Database connection working!');
    console.log('✅ You can now run the server with auto table creation');
    
  } catch (error) {
    console.log('❌ Connection failed:', error.message);
    console.log('');
    console.log('💡 Let\'s try LocalDB instead...');
    
    // Try LocalDB as fallback
    await testLocalDB();
  }
}

async function testLocalDB() {
  const localDbConfig = {
    server: '(localdb)\\MSSQLLocalDB',
    database: 'master',
    
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
  
  try {
    console.log('🔍 Testing LocalDB connection...');
    console.log('Server: (localdb)\\MSSQLLocalDB');
    
    const pool = await sql.connect(localDbConfig);
    console.log('✅ LocalDB connection successful!');
    
    const result = await pool.request().query('SELECT @@VERSION as version');
    console.log('   Version:', result.recordset[0].version.substring(0, 80) + '...');
    
    await pool.close();
    console.log('');
    console.log('🎯 RECOMMENDATION: Use LocalDB configuration');
    console.log('Update your database.js config to use:');
    console.log('server: "(localdb)\\\\MSSQLLocalDB"');
    
  } catch (localError) {
    console.log('❌ LocalDB also failed:', localError.message);
    console.log('');
    console.log('🔧 Manual setup required - check SQL Server installation');
  }
}

testNamedPipeConnection().catch(console.error);
