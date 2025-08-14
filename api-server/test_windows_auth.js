const sql = require('mssql');
const { config } = require('./config/database.js');

async function quickWindowsAuthTest() {
  console.log('🔍 Testing Windows Authentication Connection...');
  console.log('Server: DESKTOP-E2H6BA3\\SQLEXPRESS');
  console.log('Authentication: Windows Authentication (like SSMS)');
  console.log('');
  
  try {
    console.log('📡 Connecting...');
    const pool = await sql.connect(config);
    console.log('✅ Connection SUCCESS!');
    
    // Test query
    const result = await pool.request().query(`
      SELECT 
        @@SERVERNAME as serverName,
        SYSTEM_USER as currentUser,
        DB_NAME() as currentDB,
        GETDATE() as currentTime
    `);
    
    const row = result.recordset[0];
    console.log('📋 Connection Details:');
    console.log('   Server Name:', row.serverName);
    console.log('   Current User:', row.currentUser);
    console.log('   Database:', row.currentDB);
    console.log('   Current Time:', row.currentTime);
    
    // Check if GrievanceManagementDB exists
    console.log('\n🗃️ Checking for GrievanceManagementDB...');
    const dbCheck = await pool.request().query(`
      SELECT COUNT(*) as dbExists 
      FROM sys.databases 
      WHERE name = 'GrievanceManagementDB'
    `);
    
    if (dbCheck.recordset[0].dbExists > 0) {
      console.log('✅ GrievanceManagementDB already exists');
    } else {
      console.log('🛠️ Creating GrievanceManagementDB...');
      await pool.request().query('CREATE DATABASE GrievanceManagementDB');
      console.log('✅ Database created successfully!');
    }
    
    await pool.close();
    console.log('\n🎯 SUCCESS! Your database is ready for auto table creation.');
    console.log('✅ You can now start the server.');
    
  } catch (error) {
    console.log('❌ Connection failed:', error.message);
    console.log('\nTroubleshooting:');
    console.log('- Make sure SQL Server Express service is running');
    console.log('- Check if TCP/IP protocol is enabled');
    console.log('- Verify Windows Authentication is enabled');
  }
}

quickWindowsAuthTest().catch(console.error);
