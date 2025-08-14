const sql = require('mssql');

async function addAdminCommentsColumn() {
  const config = {
    server: 'localhost',
    database: 'GrievanceManagementDB',
    user: 'sa',
    password: 'Sid91221',
    port: 1433,
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

  try {
    console.log('🔗 Connecting to database...');
    const pool = await sql.connect(config);
    
    console.log('✅ Connected to database');
    
    // Check if column exists
    const checkResult = await pool.request().query(`
      SELECT * FROM sys.columns 
      WHERE object_id = OBJECT_ID('dbo.grievances') 
      AND name = 'admin_comments'
    `);
    
    if (checkResult.recordset.length === 0) {
      console.log('📝 Adding admin_comments column...');
      
      await pool.request().query(`
        ALTER TABLE grievances 
        ADD admin_comments NVARCHAR(MAX) NULL
      `);
      
      console.log('✅ admin_comments column added successfully!');
    } else {
      console.log('ℹ️ admin_comments column already exists');
    }
    
    await pool.close();
    console.log('🔒 Database connection closed');
    
  } catch (error) {
    console.error('❌ Error adding admin_comments column:', error);
  }
}

addAdminCommentsColumn();
