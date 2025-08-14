const sql = require('mssql');
const fs = require('fs');

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
  }
};

async function runSQL() {
  try {
    const pool = await sql.connect(config);
    console.log('✅ Connected to SQL Server');
    
    const sqlScript = fs.readFileSync('../sql/add_chat_tables.sql', 'utf8');
    const commands = sqlScript.split('GO').filter(cmd => cmd.trim());
    
    for (let i = 0; i < commands.length; i++) {
      const command = commands[i].trim();
      if (command) {
        console.log(`Executing command ${i + 1}/${commands.length}...`);
        try {
          await pool.request().query(command);
        } catch (error) {
          if (error.message.includes('already exists')) {
            console.log(`⚠️ Skipping existing object: ${error.message.split("'")[1]}`);
          } else {
            throw error;
          }
        }
      }
    }
    
    console.log('🎉 Chat tables setup completed successfully!');
    
    // Test query to check if tables exist
    const result = await pool.request().query(`
      SELECT COUNT(*) as count FROM ChatConversations;
    `);
    console.log(`📊 Found ${result.recordset[0].count} conversations in database`);
    
    await pool.close();
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

runSQL();
