const sql = require('mssql');

const config = {
  server: 'localhost',
  database: 'GrievanceManagementDB',
  user: 'sa',
  password: 'Sid91221',
  port: 1433,
  options: {
    encrypt: false,
    trustServerCertificate: true
  }
};

async function checkCitizens() {
  try {
    await sql.connect(config);
    
    console.log('=== Citizens table schema ===');
    const schema = await sql.query(`SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'citizens'`);
    console.log('Citizens columns:', schema.recordset.map(r => r.COLUMN_NAME));
    
    console.log('\n=== Sample citizens data ===');
    const data = await sql.query('SELECT TOP 3 * FROM citizens');
    console.log('Sample data:', data.recordset);
    
    console.log('\n=== Check if departments/officers tables exist ===');
    const tables = await sql.query(`SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'`);
    console.log('All tables:', tables.recordset.map(r => r.TABLE_NAME));
    
    await sql.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

checkCitizens();
