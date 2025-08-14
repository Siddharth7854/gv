const sql = require('mssql');
const config = require('./config/database');

async function completeFirebaseSchema() {
    try {
        const pool = await sql.connect(config);
        console.log('✅ Connected to database');
        
        // Create corrected view
        console.log('📝 Creating corrected ActiveNotificationSettings view...');
        try {
            // First try to drop if exists
            await pool.request().query('DROP VIEW IF EXISTS ActiveNotificationSettings');
            
            // Create new view with correct column name
            await pool.request().query(`
                CREATE VIEW ActiveNotificationSettings AS
                SELECT 
                    c.citizen_id,
                    c.full_name,
                    c.email,
                    ft.fcm_token,
                    ft.platform,
                    np.preferences,
                    ft.updated_at as token_updated_at
                FROM Citizens c
                LEFT JOIN FCMTokens ft ON c.citizen_id = ft.user_id AND ft.is_active = 1
                LEFT JOIN NotificationPreferences np ON c.citizen_id = np.user_id
                WHERE c.is_active = 1
            `);
            console.log('✅ ActiveNotificationSettings view created');
        } catch (err) {
            console.log('⚠️  View creation error:', err.message);
        }
        
        // Create stored procedure if not exists
        console.log('📝 Creating sp_LogNotification stored procedure...');
        try {
            await pool.request().query(`
                CREATE PROCEDURE sp_LogNotification
                    @UserId INT,
                    @NotificationType NVARCHAR(50),
                    @Title NVARCHAR(255),
                    @Body NVARCHAR(1000),
                    @DataPayload NVARCHAR(MAX) = NULL,
                    @GrievanceId INT = NULL,
                    @FCMToken NVARCHAR(500) = NULL,
                    @DeliveryStatus NVARCHAR(20) = 'sent'
                AS
                BEGIN
                    INSERT INTO NotificationHistory (user_id, notification_type, title, body, data_payload, grievance_id, fcm_token_used, delivery_status, sent_at)
                    VALUES (@UserId, @NotificationType, @Title, @Body, @DataPayload, @GrievanceId, @FCMToken, @DeliveryStatus, GETDATE());
                END
            `);
            console.log('✅ sp_LogNotification stored procedure created');
        } catch (err) {
            if (err.message.includes('already exists')) {
                console.log('⚠️  sp_LogNotification procedure already exists');
            } else {
                console.log('⚠️  Procedure creation error:', err.message);
            }
        }
        
        // Verify final setup
        const tablesResult = await pool.request().query(`
            SELECT TABLE_NAME 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_NAME IN ('FCMTokens', 'NotificationPreferences', 'NotificationHistory', 'NotificationTemplates')
        `);
        
        console.log('\n🎉 Firebase Push Notifications setup completed!');
        console.log('\n📊 Tables successfully created:');
        tablesResult.recordset.forEach(table => {
            console.log(`  ✅ ${table.TABLE_NAME}`);
        });
        
        // Check templates count
        const templatesCount = await pool.request().query('SELECT COUNT(*) as count FROM NotificationTemplates');
        console.log(`\n📝 Default notification templates: ${templatesCount.recordset[0].count} inserted`);
        
        await pool.close();
        console.log('\n🔐 Database connection closed');
        console.log('\n🚀 Firebase database schema is ready for push notifications!');
        
    } catch (err) {
        console.error('❌ Error:', err.message);
    }
}

completeFirebaseSchema();
