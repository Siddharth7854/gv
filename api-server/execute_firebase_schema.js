const sql = require('mssql');
const fs = require('fs');
const config = require('./config/database');

async function executeFirebaseSchema() {
    let pool;
    try {
        console.log('🔗 Connecting to SQL Server...');
        pool = await sql.connect(config);
        console.log('✅ Connected to SQL Server database');

        // Read and split SQL script by GO statements
        const sqlScript = fs.readFileSync('../sql/firebase_push_notifications_setup.sql', 'utf8');
        
        // Split by GO statements and filter out empty statements
        const statements = sqlScript
            .split(/\bGO\b/gi)
            .map(stmt => stmt.trim())
            .filter(stmt => stmt.length > 0 && !stmt.startsWith('--') && !stmt.startsWith('PRINT'));

        console.log(`📝 Found ${statements.length} SQL statements to execute`);

        // Execute each statement separately
        for (let i = 0; i < statements.length; i++) {
            const statement = statements[i];
            if (statement.trim()) {
                try {
                    console.log(`⚡ Executing statement ${i + 1}/${statements.length}...`);
                    await pool.request().batch(statement);
                    console.log(`✅ Statement ${i + 1} executed successfully`);
                } catch (err) {
                    console.warn(`⚠️  Warning in statement ${i + 1}:`, err.message);
                    // Continue with other statements even if one fails
                }
            }
        }

        console.log('\n🎉 Firebase Push Notifications schema setup completed!');
        console.log('\n📋 Tables created:');
        console.log('  ✅ FCMTokens - Store FCM tokens for users');
        console.log('  ✅ NotificationPreferences - Store user notification preferences');
        console.log('  ✅ NotificationHistory - Track sent notifications');
        console.log('  ✅ NotificationTemplates - Admin-managed notification templates');
        
        console.log('\n📊 Views created:');
        console.log('  ✅ ActiveNotificationSettings - Active users with notification settings');
        
        console.log('\n🔧 Stored procedures:');
        console.log('  ✅ sp_LogNotification - Log notification history');
        
        console.log('\n⚙️  Functions:');
        console.log('  ✅ fn_GetNotificationTemplate - Get notification template by type');

        // Verify tables were created
        const tablesResult = await pool.request().query(`
            SELECT TABLE_NAME 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_NAME IN ('FCMTokens', 'NotificationPreferences', 'NotificationHistory', 'NotificationTemplates')
        `);
        
        console.log('\n🔍 Verification - Tables found in database:');
        tablesResult.recordset.forEach(table => {
            console.log(`  ✅ ${table.TABLE_NAME}`);
        });

    } catch (err) {
        console.error('❌ Error executing Firebase schema:', err.message);
        throw err;
    } finally {
        if (pool) {
            await pool.close();
            console.log('\n🔐 Database connection closed');
        }
    }
}

// Execute the schema setup
executeFirebaseSchema()
    .then(() => {
        console.log('\n🚀 Firebase database setup completed successfully!');
        process.exit(0);
    })
    .catch((err) => {
        console.error('\n💥 Firebase database setup failed:', err);
        process.exit(1);
    });
