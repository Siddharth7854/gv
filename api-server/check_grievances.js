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

async function checkGrievances() {
  try {
    await sql.connect(config);
    console.log('=== All Grievances ===');
    
    const result = await sql.query(`
      SELECT grievance_id, citizen_id, title, status 
      FROM Grievances 
      ORDER BY grievance_id
    `);
    
    console.log('Grievances data:');
    result.recordset.forEach(g => {
      console.log(`ID: ${g.grievance_id}, Citizen: ${g.citizen_id}, Title: "${g.title}", Status: ${g.status}`);
    });
    
    console.log('\n=== Grievance 5 Details ===');
    const grievance5 = await sql.query(`
      SELECT * FROM Grievances WHERE grievance_id = 5
    `);
    
    if (grievance5.recordset.length > 0) {
      console.log('Grievance 5:', grievance5.recordset[0]);
    } else {
      console.log('Grievance 5 not found');
    }
    
    await sql.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

checkGrievances();
