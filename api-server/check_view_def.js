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

async function checkViewDefinition() {
  try {
    await sql.connect(config);
    
    const result = await sql.query(`
      SELECT OBJECT_DEFINITION(OBJECT_ID('vw_GrievanceDetails')) AS ViewDefinition
    `);
    
    console.log('=== View Definition ===');
    console.log(result.recordset[0].ViewDefinition);
    
    await sql.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

checkViewDefinition();
