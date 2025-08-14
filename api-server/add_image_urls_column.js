const sql = require('mssql');
const dbConfig = require('./config/database');

async function addImageUrlsColumn() {
  try {
    console.log('🔗 Connecting to database...');
    const pool = await sql.connect(dbConfig.config);
    
    // Check if column already exists
    const checkResult = await pool.request().query(`
      SELECT COUNT(*) as column_exists
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_NAME = 'GrievanceStatusHistory' 
        AND COLUMN_NAME = 'image_urls'
    `);
    
    if (checkResult.recordset[0].column_exists > 0) {
      console.log('✅ image_urls column already exists in GrievanceStatusHistory table');
      return;
    }
    
    // Add image_urls column
    console.log('📝 Adding image_urls column to GrievanceStatusHistory table...');
    await pool.request().query(`
      ALTER TABLE GrievanceStatusHistory 
      ADD image_urls NVARCHAR(MAX) NULL
    `);
    
    console.log('✅ Successfully added image_urls column to GrievanceStatusHistory table');
    
    // Close connection
    await pool.close();
    console.log('🔐 Database connection closed');
    
  } catch (error) {
    console.error('❌ Error updating database:', error);
    process.exit(1);
  }
}

// Run the update
addImageUrlsColumn();
