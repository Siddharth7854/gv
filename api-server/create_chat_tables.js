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
    trustServerCertificate: true
  }
};

async function executeSqlScript() {
  try {
    console.log('🔌 Connecting to SQL Server...');
    await sql.connect(config);
    
    console.log('📄 Reading SQL script...');
    const sqlScript = fs.readFileSync('../sql/add_chat_tables.sql', 'utf8');
    
    // Split by GO statements
    const batches = sqlScript.split(/^\s*GO\s*$/gim);
    
    console.log('⚡ Executing SQL batches...');
    for (let i = 0; i < batches.length; i++) {
      const batch = batches[i].trim();
      if (batch) {
        console.log(`Executing batch ${i + 1}/${batches.length}...`);
        await sql.query(batch);
      }
    }
    
    console.log('✅ Chat tables created successfully!');
    
    // Test the new tables
    console.log('\n📊 Testing chat tables...');
    const result = await sql.query('SELECT * FROM vw_ChatConversationSummary');
    console.log(`Found ${result.recordset.length} conversations in database`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await sql.close();
  }
}

executeSqlScript();
