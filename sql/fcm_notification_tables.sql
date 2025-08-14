-- SQL Tables for FCM Notifications and History
-- Run these queries in your SQL Server database

-- 1. FCM Tokens table (if not exists)
IF NOT EXISTS (SELECT *
FROM sysobjects
WHERE name='FCMTokens' AND xtype='U')
CREATE TABLE FCMTokens
(
    fcm_token_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    fcm_token NVARCHAR(500) NOT NULL,
    platform NVARCHAR(50) DEFAULT 'flutter',
    device_info NVARCHAR(MAX),
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES citizens(citizen_id) ON DELETE CASCADE
);

-- 2. Notification History table
IF NOT EXISTS (SELECT *
FROM sysobjects
WHERE name='notification_history' AND xtype='U')
CREATE TABLE notification_history
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(255) NOT NULL,
    body NVARCHAR(MAX) NOT NULL,
    recipient_count INT DEFAULT 0,
    sender_id NVARCHAR(100),
    data_payload NVARCHAR(MAX),
    notification_type NVARCHAR(50) DEFAULT 'general',
    priority NVARCHAR(20) DEFAULT 'normal',
    status NVARCHAR(20) DEFAULT 'pending',
    created_at DATETIME2 DEFAULT GETDATE(),
    sent_at DATETIME2,
    error_message NVARCHAR(MAX)
);

-- 3. Notification Recipients table (track individual deliveries)
IF NOT EXISTS (SELECT *
FROM sysobjects
WHERE name='notification_recipients' AND xtype='U')
CREATE TABLE notification_recipients
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    notification_id INT NOT NULL,
    user_id INT NOT NULL,
    fcm_token NVARCHAR(500),
    delivery_status NVARCHAR(20) DEFAULT 'pending',
    -- 'pending', 'sent', 'delivered', 'failed'
    sent_at DATETIME2,
    delivered_at DATETIME2,
    error_message NVARCHAR(MAX),
    platform NVARCHAR(50),
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (notification_id) REFERENCES notification_history(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES citizens(citizen_id) ON DELETE CASCADE
);

-- 4. User Notification Preferences table
IF NOT EXISTS (SELECT *
FROM sysobjects
WHERE name='user_notification_preferences' AND xtype='U')
CREATE TABLE user_notification_preferences
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    notification_type NVARCHAR(50) NOT NULL,
    -- 'grievance_status', 'chat_message', 'admin_alert', etc.
    is_enabled BIT DEFAULT 1,
    delivery_method NVARCHAR(20) DEFAULT 'push',
    -- 'push', 'email', 'sms'
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES citizens(citizen_id) ON DELETE CASCADE,
    UNIQUE(user_id, notification_type, delivery_method)
);

-- Create indexes for better performance
CREATE INDEX IX_FCMTokens_UserID ON FCMTokens(user_id);
CREATE INDEX IX_FCMTokens_IsActive ON FCMTokens(is_active);
CREATE INDEX IX_NotificationHistory_CreatedAt ON notification_history(created_at);
CREATE INDEX IX_NotificationRecipients_NotificationID ON notification_recipients(notification_id);
CREATE INDEX IX_NotificationRecipients_UserID ON notification_recipients(user_id);
CREATE INDEX IX_UserNotificationPreferences_UserID ON user_notification_preferences(user_id);

-- Insert default notification preferences for existing users
INSERT INTO user_notification_preferences
    (user_id, notification_type, is_enabled, delivery_method)
SELECT
    citizen_id,
    notification_type,
    1,
    'push'
FROM citizens
CROSS JOIN (
    VALUES
        ('grievance_status'),
        ('grievance_update'),
        ('chat_message'),
        ('admin_alert'),
        ('system_announcement')
) AS notification_types(notification_type)
WHERE NOT EXISTS (
    SELECT 1
FROM user_notification_preferences unp
WHERE unp.user_id = citizens.citizen_id
    AND unp.notification_type = notification_types.notification_type
    AND unp.delivery_method = 'push'
);

-- Sample data for testing
-- Insert sample FCM tokens (these will be replaced by real tokens from the app)
INSERT INTO FCMTokens
    (user_id, fcm_token, platform, is_active)
SELECT TOP 3
    citizen_id,
    'mock-fcm-token-' + CAST(citizen_id AS NVARCHAR) + '-' + platform + '-test',
    'android',
    1
FROM citizens
WHERE NOT EXISTS (SELECT 1
FROM FCMTokens
WHERE user_id = citizens.citizen_id);

-- Create stored procedure for sending notifications
CREATE OR ALTER PROCEDURE sp_SendNotificationToUsers
    @Title NVARCHAR(255),
    @Body NVARCHAR(MAX),
    @UserIds NVARCHAR(MAX) = NULL,
    -- Comma-separated user IDs
    @Roles NVARCHAR(MAX) = NULL,
    -- Comma-separated roles
    @NotificationType NVARCHAR(50) = 'general',
    @DataPayload NVARCHAR(MAX) = NULL,
    @SenderId NVARCHAR(100) = 'system'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NotificationId INT;
    DECLARE @RecipientCount INT = 0;

    -- Insert notification record
    INSERT INTO notification_history
        (title, body, sender_id, data_payload, notification_type, status)
    VALUES
        (@Title, @Body, @SenderId, @DataPayload, @NotificationType, 'processing');

    SET @NotificationId = SCOPE_IDENTITY();

    -- Get target users based on criteria
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = '
        INSERT INTO notification_recipients (notification_id, user_id, fcm_token, platform)
        SELECT 
            ' + CAST(@NotificationId AS NVARCHAR) + ',
            c.citizen_id,
            f.fcm_token,
            f.platform
        FROM citizens c
        INNER JOIN FCMTokens f ON c.citizen_id = f.user_id AND f.is_active = 1
        WHERE 1=1';

    -- Filter by user IDs if provided
    IF @UserIds IS NOT NULL AND LEN(@UserIds) > 0
    BEGIN
        SET @SQL = @SQL + ' AND c.citizen_id IN (' + @UserIds + ')';
    END

    -- Filter by roles if provided
    IF @Roles IS NOT NULL AND LEN(@Roles) > 0
    BEGIN
        SET @SQL = @SQL + ' AND c.role IN (''' + REPLACE(@Roles, ',', ''',''') + ''')';
    END

    EXEC sp_executesql @SQL;

    -- Update recipient count
    SELECT @RecipientCount = COUNT(*)
    FROM notification_recipients
    WHERE notification_id = @NotificationId;

    UPDATE notification_history 
    SET recipient_count = @RecipientCount, status = 'ready'
    WHERE id = @NotificationId;

    -- Return notification details
    SELECT
        @NotificationId AS notification_id,
        @RecipientCount AS recipient_count,
        @Title AS title,
        @Body AS body;
END;

PRINT '✅ FCM Notification tables and procedures created successfully';
PRINT '📱 Ready to handle Firebase Cloud Messaging';
PRINT '🔔 Use the notification API endpoints to send notifications';
PRINT '';
PRINT 'Next steps:';
PRINT '1. Start your API server: cd api-server && npm start';
PRINT '2. Test notification endpoint: POST /api/notifications/test';
PRINT '3. Register FCM tokens from your Flutter app';
PRINT '4. Send real notifications using Firebase Admin SDK';
