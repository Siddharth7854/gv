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

async function checkView() {
  try {
    await sql.connect(config);
    
    console.log('=== Check if view exists ===');
    const viewCheck = await sql.query(`
      SELECT name FROM sys.views WHERE name = 'vw_GrievanceDetails'
    `);
    
    if (viewCheck.recordset.length === 0) {
      console.log('❌ View vw_GrievanceDetails does NOT exist!');
      
      console.log('\n=== Available views ===');
      const allViews = await sql.query(`SELECT name FROM sys.views`);
      console.log('Available views:', allViews.recordset.map(v => v.name));
      
      console.log('\n=== Direct query from Grievances table ===');
      const directResult = await sql.query(`
        SELECT grievance_id, citizen_id, title, status 
        FROM Grievances 
        WHERE grievance_id = 5
      `);
      console.log('Direct query result:', directResult.recordset[0]);
      
    } else {
      console.log('✅ View vw_GrievanceDetails exists');
      
      console.log('\n=== Query view for grievance 5 ===');
      const viewResult = await sql.query(`
        SELECT * FROM vw_GrievanceDetails WHERE grievance_id = 5
      `);
      
      if (viewResult.recordset.length > 0) {
        console.log('View result:', viewResult.recordset[0]);
      } else {
        console.log('❌ Grievance 5 not found in view');
      }
    }
    
    await sql.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

checkView();
