-- FCM Tokens Table
CREATE TABLE FCMTokens
(
    fcm_token_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    fcm_token NVARCHAR(500) NOT NULL,
    platform NVARCHAR(50) DEFAULT 'flutter',
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    is_active BIT DEFAULT 1,

    FOREIGN KEY (user_id) REFERENCES Citizens(citizen_id) ON DELETE CASCADE,
    INDEX IX_FCMTokens_UserId (user_id),
    INDEX IX_FCMTokens_Token (fcm_token),
    INDEX IX_FCMTokens_Active (is_active)
);

-- Notification Preferences Table
CREATE TABLE NotificationPreferences
(
    preference_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    preferences NVARCHAR(MAX) NOT NULL,
    -- JSON string storing preference settings
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),

    FOREIGN KEY (user_id) REFERENCES Citizens(citizen_id) ON DELETE CASCADE,
    INDEX IX_NotificationPreferences_UserId (user_id)
);

-- Notification History Table (for tracking sent notifications)
CREATE TABLE NotificationHistory
(
    notification_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    notification_type NVARCHAR(50) NOT NULL,
    -- 'grievance_status', 'chat_message', 'admin_alert', etc.
    title NVARCHAR(255) NOT NULL,
    body NVARCHAR(1000) NOT NULL,
    data_payload NVARCHAR(MAX),
    -- JSON string with additional data
    sent_at DATETIME2 DEFAULT GETDATE(),
    delivery_status NVARCHAR(20) DEFAULT 'sent',
    -- 'sent', 'delivered', 'failed'
    fcm_token_used NVARCHAR(500),
    grievance_id INT NULL,
    -- Reference to grievance if applicable

    FOREIGN KEY (user_id) REFERENCES Citizens(citizen_id) ON DELETE CASCADE,
    FOREIGN KEY (grievance_id) REFERENCES Grievances(grievance_id) ON DELETE SET NULL,
    INDEX IX_NotificationHistory_UserId (user_id),
    INDEX IX_NotificationHistory_Type (notification_type),
    INDEX IX_NotificationHistory_SentAt (sent_at),
    INDEX IX_NotificationHistory_GrievanceId (grievance_id)
);

-- Notification Templates Table (for admin to create notification templates)
CREATE TABLE NotificationTemplates
(
    template_id INT IDENTITY(1,1) PRIMARY KEY,
    template_name NVARCHAR(100) NOT NULL,
    notification_type NVARCHAR(50) NOT NULL,
    title_template NVARCHAR(255) NOT NULL,
    body_template NVARCHAR(1000) NOT NULL,
    is_active BIT DEFAULT 1,
    created_by INT NOT NULL,
    -- Admin user who created this template
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),

    INDEX IX_NotificationTemplates_Type (notification_type),
    INDEX IX_NotificationTemplates_Active (is_active)
);

-- Add some default notification templates
INSERT INTO NotificationTemplates
    (template_name, notification_type, title_template, body_template, created_by)
VALUES
    ('Grievance Status Update', 'grievance_status', 'Grievance #{grievance_id} - Status Updated', 'Your grievance "{title}" has been updated to {status}. {comments}', 1),
    ('New Chat Message', 'chat_message', 'New Message from Admin', 'You have received a new message regarding your grievance #{grievance_id}', 1),
    ('Grievance Submitted', 'grievance_status', 'Grievance Submitted Successfully', 'Your grievance "{title}" has been submitted successfully. Reference ID: {grievance_id}', 1),
    ('Grievance Resolved', 'grievance_status', 'Grievance Resolved', 'Great news! Your grievance "{title}" has been resolved. {comments}', 1),
    ('System Maintenance', 'admin_alert', 'System Maintenance Notice', 'The system will be under maintenance from {start_time} to {end_time}. Please plan accordingly.', 1),
    ('Follow-up Reminder', 'reminders', 'Grievance Follow-up Reminder', 'This is a reminder to follow up on your grievance "{title}" (ID: {grievance_id})', 1);

-- Create indexes for better performance
CREATE INDEX IX_Citizens_FCMTokens ON FCMTokens(user_id) INCLUDE (fcm_token, is_active);
CREATE INDEX IX_NotificationHistory_UserType ON NotificationHistory(user_id, notification_type) INCLUDE (sent_at);

-- Add FCM token column to admin users table if exists
IF EXISTS (SELECT *
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'AdminUsers')
BEGIN
    IF NOT EXISTS (SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'AdminUsers' AND COLUMN_NAME = 'fcm_token')
    BEGIN
        ALTER TABLE AdminUsers ADD fcm_token NVARCHAR(500) NULL;
        CREATE INDEX IX_AdminUsers_FCMToken ON AdminUsers(fcm_token);
    END
END
GO

-- Create a view for active notification settings
CREATE VIEW ActiveNotificationSettings
AS
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
    WHERE c.status = 'active';
GO

-- Create stored procedure for sending notifications
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
    INSERT INTO NotificationHistory
        (user_id, notification_type, title, body, data_payload, grievance_id, fcm_token_used, delivery_status, sent_at)
    VALUES
        (@UserId, @NotificationType, @Title, @Body, @DataPayload, @GrievanceId, @FCMToken, @DeliveryStatus, GETDATE());
END;
GO

-- Create function to get notification template
CREATE FUNCTION fn_GetNotificationTemplate(@TemplateType NVARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 1
    title_template,
    body_template
FROM NotificationTemplates
WHERE notification_type = @TemplateType
    AND is_active = 1
ORDER BY created_at DESC
);
GO

PRINT 'Firebase Cloud Messaging database tables created successfully!';
PRINT 'Tables created:';
PRINT '- FCMTokens: Store FCM tokens for users';
PRINT '- NotificationPreferences: Store user notification preferences';
PRINT '- NotificationHistory: Track sent notifications';
PRINT '- NotificationTemplates: Admin-managed notification templates';
PRINT '';
PRINT 'Views created:';
PRINT '- ActiveNotificationSettings: Active users with notification settings';
PRINT '';
PRINT 'Stored procedures:';
PRINT '- sp_LogNotification: Log notification history';
PRINT '';
PRINT 'Functions:';
PRINT '- fn_GetNotificationTemplate: Get notification template by type';
