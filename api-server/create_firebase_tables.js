const sql = require('mssql');
const config = require('./config/database');

async function createFirebaseSchema() {
    let pool;
    try {
        console.log('🔗 Connecting to SQL Server...');
        pool = await sql.connect(config);
        console.log('✅ Connected to SQL Server database');

        // 1. Create FCMTokens table
        console.log('📝 Creating FCMTokens table...');
        try {
            await pool.request().query(`
                CREATE TABLE FCMTokens (
                    fcm_token_id INT IDENTITY(1,1) PRIMARY KEY,
                    user_id INT NOT NULL,
                    fcm_token NVARCHAR(500) NOT NULL,
                    platform NVARCHAR(50) DEFAULT 'flutter',
                    created_at DATETIME2 DEFAULT GETDATE(),
                    updated_at DATETIME2 DEFAULT GETDATE(),
                    is_active BIT DEFAULT 1,
                    FOREIGN KEY (user_id) REFERENCES Citizens(citizen_id) ON DELETE CASCADE
                )
            `);
            console.log('✅ FCMTokens table created');
        } catch (err) {
            if (err.message.includes('already an object')) {
                console.log('⚠️  FCMTokens table already exists');
            } else {
                throw err;
            }
        }

        // 2. Create NotificationPreferences table
        console.log('📝 Creating NotificationPreferences table...');
        try {
            await pool.request().query(`
                CREATE TABLE NotificationPreferences (
                    preference_id INT IDENTITY(1,1) PRIMARY KEY,
                    user_id INT NOT NULL,
                    preferences NVARCHAR(MAX) NOT NULL,
                    created_at DATETIME2 DEFAULT GETDATE(),
                    updated_at DATETIME2 DEFAULT GETDATE(),
                    FOREIGN KEY (user_id) REFERENCES Citizens(citizen_id) ON DELETE CASCADE
                )
            `);
            console.log('✅ NotificationPreferences table created');
        } catch (err) {
            if (err.message.includes('already an object')) {
                console.log('⚠️  NotificationPreferences table already exists');
            } else {
                throw err;
            }
        }

        // 3. Create NotificationHistory table
        console.log('📝 Creating NotificationHistory table...');
        try {
            await pool.request().query(`
                CREATE TABLE NotificationHistory (
                    notification_id INT IDENTITY(1,1) PRIMARY KEY,
                    user_id INT NOT NULL,
                    notification_type NVARCHAR(50) NOT NULL,
                    title NVARCHAR(255) NOT NULL,
                    body NVARCHAR(1000) NOT NULL,
                    data_payload NVARCHAR(MAX),
                    sent_at DATETIME2 DEFAULT GETDATE(),
                    delivery_status NVARCHAR(20) DEFAULT 'sent',
                    fcm_token_used NVARCHAR(500),
                    grievance_id INT NULL,
                    FOREIGN KEY (user_id) REFERENCES Citizens(citizen_id) ON DELETE CASCADE,
                    FOREIGN KEY (grievance_id) REFERENCES Grievances(grievance_id) ON DELETE SET NULL
                )
            `);
            console.log('✅ NotificationHistory table created');
        } catch (err) {
            if (err.message.includes('already an object')) {
                console.log('⚠️  NotificationHistory table already exists');
            } else {
                throw err;
            }
        }

        // 4. Create NotificationTemplates table
        console.log('📝 Creating NotificationTemplates table...');
        try {
            await pool.request().query(`
                CREATE TABLE NotificationTemplates (
                    template_id INT IDENTITY(1,1) PRIMARY KEY,
                    template_name NVARCHAR(100) NOT NULL,
                    notification_type NVARCHAR(50) NOT NULL,
                    title_template NVARCHAR(255) NOT NULL,
                    body_template NVARCHAR(1000) NOT NULL,
                    is_active BIT DEFAULT 1,
                    created_by INT NOT NULL,
                    created_at DATETIME2 DEFAULT GETDATE(),
                    updated_at DATETIME2 DEFAULT GETDATE()
                )
            `);
            console.log('✅ NotificationTemplates table created');
        } catch (err) {
            if (err.message.includes('already an object')) {
                console.log('⚠️  NotificationTemplates table already exists');
            } else {
                throw err;
            }
        }

        // 5. Create indexes
        console.log('📝 Creating indexes...');
        const indexes = [
            'CREATE INDEX IX_FCMTokens_UserId ON FCMTokens(user_id)',
            'CREATE INDEX IX_FCMTokens_Token ON FCMTokens(fcm_token)',
            'CREATE INDEX IX_FCMTokens_Active ON FCMTokens(is_active)',
            'CREATE INDEX IX_NotificationPreferences_UserId ON NotificationPreferences(user_id)',
            'CREATE INDEX IX_NotificationHistory_UserId ON NotificationHistory(user_id)',
            'CREATE INDEX IX_NotificationHistory_Type ON NotificationHistory(notification_type)',
            'CREATE INDEX IX_NotificationHistory_SentAt ON NotificationHistory(sent_at)',
            'CREATE INDEX IX_NotificationHistory_GrievanceId ON NotificationHistory(grievance_id)',
            'CREATE INDEX IX_NotificationTemplates_Type ON NotificationTemplates(notification_type)',
            'CREATE INDEX IX_NotificationTemplates_Active ON NotificationTemplates(is_active)'
        ];

        for (const indexSql of indexes) {
            try {
                await pool.request().query(indexSql);
            } catch (err) {
                if (!err.message.includes('already exists')) {
                    console.log(`⚠️  Index error: ${err.message}`);
                }
            }
        }
        console.log('✅ Indexes created');

        // 6. Insert default notification templates
        console.log('📝 Inserting default notification templates...');
        try {
            await pool.request().query(`
                INSERT INTO NotificationTemplates (template_name, notification_type, title_template, body_template, created_by)
                VALUES 
                ('Grievance Status Update', 'grievance_status', 'Grievance #{grievance_id} - Status Updated', 'Your grievance "{title}" has been updated to {status}. {comments}', 1),
                ('New Chat Message', 'chat_message', 'New Message from Admin', 'You have received a new message regarding your grievance #{grievance_id}', 1),
                ('Grievance Submitted', 'grievance_status', 'Grievance Submitted Successfully', 'Your grievance "{title}" has been submitted successfully. Reference ID: {grievance_id}', 1),
                ('Grievance Resolved', 'grievance_status', 'Grievance Resolved', 'Great news! Your grievance "{title}" has been resolved. {comments}', 1),
                ('System Maintenance', 'admin_alert', 'System Maintenance Notice', 'The system will be under maintenance from {start_time} to {end_time}. Please plan accordingly.', 1),
                ('Follow-up Reminder', 'reminders', 'Grievance Follow-up Reminder', 'This is a reminder to follow up on your grievance "{title}" (ID: {grievance_id})', 1)
            `);
            console.log('✅ Default notification templates inserted');
        } catch (err) {
            if (err.message.includes('duplicate key')) {
                console.log('⚠️  Default templates already exist');
            } else {
                console.log(`⚠️  Template insert error: ${err.message}`);
            }
        }

        // 7. Create view for active notification settings
        console.log('📝 Creating ActiveNotificationSettings view...');
        try {
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
                WHERE c.status = 'active'
            `);
            console.log('✅ ActiveNotificationSettings view created');
        } catch (err) {
            if (err.message.includes('already exists')) {
                console.log('⚠️  ActiveNotificationSettings view already exists');
            } else {
                throw err;
            }
        }

        // 8. Create stored procedure
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
                throw err;
            }
        }

        // 9. Verify tables were created
        console.log('🔍 Verifying created tables...');
        const tablesResult = await pool.request().query(`
            SELECT TABLE_NAME 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_NAME IN ('FCMTokens', 'NotificationPreferences', 'NotificationHistory', 'NotificationTemplates')
        `);
        
        console.log('\n📊 Tables found in database:');
        tablesResult.recordset.forEach(table => {
            console.log(`  ✅ ${table.TABLE_NAME}`);
        });

        console.log('\n🎉 Firebase Push Notifications database schema created successfully!');

    } catch (err) {
        console.error('❌ Error creating Firebase schema:', err.message);
        throw err;
    } finally {
        if (pool) {
            await pool.close();
            console.log('\n🔐 Database connection closed');
        }
    }
}

// Execute the schema creation
createFirebaseSchema()
    .then(() => {
        console.log('\n🚀 Firebase database setup completed successfully!');
        process.exit(0);
    })
    .catch((err) => {
        console.error('\n💥 Firebase database setup failed:', err);
        process.exit(1);
    });
