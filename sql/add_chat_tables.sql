-- Add Chat System Tables to Grievance Management System
-- Author: GitHub Copilot
-- Date: August 6, 2025

USE GrievanceManagementDB;
GO

-- Chat Conversations Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'ChatConversations')
BEGIN
    CREATE TABLE ChatConversations
    (
        conversation_id INT IDENTITY(1,1) PRIMARY KEY,
        grievance_id INT NOT NULL,
        citizen_id INT NOT NULL,
        status NVARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'closed')),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (grievance_id) REFERENCES Grievances(grievance_id),
        FOREIGN KEY (citizen_id) REFERENCES Citizens(citizen_id),
        UNIQUE(grievance_id)
        -- One conversation per grievance
    );
END
GO

-- Chat Messages Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'ChatMessages')
BEGIN
    CREATE TABLE ChatMessages
    (
        message_id INT IDENTITY(1,1) PRIMARY KEY,
        conversation_id INT NOT NULL,
        sender_type NVARCHAR(10) NOT NULL CHECK (sender_type IN ('user', 'admin')),
        sender_id INT NULL,
        -- Can be citizen_id or admin_id
        message NVARCHAR(MAX) NOT NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        is_read BIT DEFAULT 0,
        FOREIGN KEY (conversation_id) REFERENCES ChatConversations(conversation_id) ON DELETE CASCADE
    );
END
GO

-- Indexes for better performance
IF NOT EXISTS (SELECT *
FROM sys.indexes
WHERE name = 'IX_ChatConversations_GrievanceId')
BEGIN
    CREATE INDEX IX_ChatConversations_GrievanceId ON ChatConversations(grievance_id);
END
GO

IF NOT EXISTS (SELECT *
FROM sys.indexes
WHERE name = 'IX_ChatConversations_CitizenId')
BEGIN
    CREATE INDEX IX_ChatConversations_CitizenId ON ChatConversations(citizen_id);
END
GO

IF NOT EXISTS (SELECT *
FROM sys.indexes
WHERE name = 'IX_ChatMessages_ConversationId')
BEGIN
    CREATE INDEX IX_ChatMessages_ConversationId ON ChatMessages(conversation_id);
END
GO

IF NOT EXISTS (SELECT *
FROM sys.indexes
WHERE name = 'IX_ChatMessages_CreatedAt')
BEGIN
    CREATE INDEX IX_ChatMessages_CreatedAt ON ChatMessages(created_at DESC);
END
GO

-- View for conversation summary with unread counts
IF EXISTS (SELECT *
FROM sys.views
WHERE name = 'vw_ChatConversationSummary')
BEGIN
    DROP VIEW vw_ChatConversationSummary;
END
GO

CREATE VIEW vw_ChatConversationSummary
AS
    SELECT
        cc.conversation_id,
        cc.grievance_id,
        cc.citizen_id,
        cc.status,
        cc.created_at as conversation_created_at,
        cc.updated_at as conversation_updated_at,
        g.grievance_number,
        g.title as grievance_title,
        g.status as grievance_status,
        c.full_name as user_name,
        c.phone as user_phone,
        c.email as user_email,
        -- Last message details
        lm.message as last_message,
        lm.created_at as last_message_time,
        lm.sender_type as last_sender_type,
        -- Unread count for admin (messages from user that are unread)
        (SELECT COUNT(*)
        FROM ChatMessages cm
        WHERE cm.conversation_id = cc.conversation_id
            AND cm.sender_type = 'user'
            AND cm.is_read = 0) as unread_count
    FROM ChatConversations cc
        INNER JOIN Grievances g ON cc.grievance_id = g.grievance_id
        INNER JOIN Citizens c ON cc.citizen_id = c.citizen_id
-- Get last message
OUTER APPLY (
    SELECT TOP 1
            message,
            created_at,
            sender_type
        FROM ChatMessages cm
        WHERE cm.conversation_id = cc.conversation_id
        ORDER BY cm.created_at DESC
) lm
GO

-- Trigger to update conversation updated_at when message is added
IF EXISTS (SELECT *
FROM sys.triggers
WHERE name = 'tr_UpdateConversationTimestamp')
BEGIN
    DROP TRIGGER tr_UpdateConversationTimestamp;
END
GO

CREATE TRIGGER tr_UpdateConversationTimestamp
ON ChatMessages
AFTER INSERT
AS
BEGIN
    UPDATE ChatConversations 
    SET updated_at = GETDATE()
    WHERE conversation_id IN (SELECT DISTINCT conversation_id
    FROM inserted);
END
GO

-- Sample data for testing (remove in production)
-- Insert some test conversations if they don't exist
IF NOT EXISTS (SELECT *
FROM ChatConversations)
BEGIN
    -- First, ensure we have some test grievances
    DECLARE @citizen_id INT = (SELECT TOP 1
        citizen_id
    FROM Citizens
    ORDER BY citizen_id);
    DECLARE @grievance_id INT = (SELECT TOP 1
        grievance_id
    FROM Grievances
    ORDER BY grievance_id);

    IF @citizen_id IS NOT NULL AND @grievance_id IS NOT NULL
    BEGIN
        -- Insert test conversation
        INSERT INTO ChatConversations
            (grievance_id, citizen_id, status)
        VALUES
            (@grievance_id, @citizen_id, 'active');

        DECLARE @conversation_id INT = SCOPE_IDENTITY();

        -- Insert some test messages
        INSERT INTO ChatMessages
            (conversation_id, sender_type, sender_id, message, created_at, is_read)
        VALUES
            (@conversation_id, 'user', @citizen_id, 'Hello, maine electricity ke bare mein grievance file kiya tha. Koi update hai?', DATEADD(HOUR, -2, GETDATE()), 1),
            (@conversation_id, 'admin', NULL, 'Hi, we have received your grievance. Our team is reviewing it. We will update you soon.', DATEADD(MINUTE, -105, GETDATE()), 0),
            (@conversation_id, 'user', @citizen_id, 'Kitna time lagega approximate?', DATEADD(MINUTE, -90, GETDATE()), 1),
            (@conversation_id, 'user', @citizen_id, 'Admin bhai koi response do please', DATEADD(MINUTE, -15, GETDATE()), 0);
    END
END
GO

PRINT '✅ Chat system tables created successfully!';
PRINT '📊 Use vw_ChatConversationSummary view for admin dashboard';
PRINT '🧪 Test data inserted (remove in production)';
