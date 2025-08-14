const sql = require('mssql');
const config = require('./config/database');

async function checkCitizensTable() {
    try {
        const pool = await sql.connect(config);
        console.log('🔍 Checking Citizens table structure...');
        
        const result = await pool.request().query(`
            SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = 'Citizens'
            ORDER BY ORDINAL_POSITION
        `);
        
        console.log('\n📋 Citizens table columns:');
        result.recordset.forEach(col => {
            console.log(`  - ${col.COLUMN_NAME}: ${col.DATA_TYPE} (Nullable: ${col.IS_NULLABLE})`);
        });
        
        await pool.close();
    } catch (err) {
        console.error('Error:', err.message);
    }
}

checkCitizensTable();
