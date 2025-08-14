-- User Timeline Control System for Admin
-- Date: August 1, 2025

USE GrievanceManagementDB;
GO

-- User Activity Logs Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'UserActivityLogs')
BEGIN
    CREATE TABLE UserActivityLogs
    (
        log_id INT IDENTITY(1,1) PRIMARY KEY,
        citizen_id INT NOT NULL,
        activity_type NVARCHAR(50) NOT NULL CHECK (activity_type IN (
            'Login', 'Logout', 'Profile_Update', 'Grievance_Submit', 
            'Grievance_Update', 'Grievance_View', 'File_Upload', 
            'Password_Change', 'Account_Suspended', 'Account_Activated'
        )),
        activity_description NVARCHAR(500),
        ip_address NVARCHAR(45),
        user_agent NVARCHAR(500),
        session_id NVARCHAR(100),
        status NVARCHAR(20) DEFAULT 'Success' CHECK (status IN ('Success', 'Failed', 'Blocked', 'Forced')),
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (citizen_id) REFERENCES Citizens(citizen_id) ON DELETE CASCADE
    );

    -- Index for better performance
    CREATE INDEX IX_UserActivityLogs_CitizenId_CreatedAt ON UserActivityLogs (citizen_id, created_at DESC);
    CREATE INDEX IX_UserActivityLogs_ActivityType ON UserActivityLogs (activity_type);
END
GO

-- User Timeline Control Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'UserTimelineControl')
BEGIN
    CREATE TABLE UserTimelineControl
    (
        control_id INT IDENTITY(1,1) PRIMARY KEY,
        citizen_id INT NOT NULL,
        control_type NVARCHAR(50) NOT NULL CHECK (control_type IN (
            'Account_Suspension', 'Login_Restriction', 'Grievance_Restriction',
            'Upload_Restriction', 'Profile_Lock', 'Activity_Monitor'
        )),
        is_active BIT DEFAULT 1,
        start_date DATETIME2 DEFAULT GETDATE(),
        end_date DATETIME2,
        reason NVARCHAR(500) NOT NULL,
        applied_by_admin_id INT NOT NULL,
        notes NVARCHAR(1000),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (citizen_id) REFERENCES Citizens(citizen_id) ON DELETE CASCADE,
        FOREIGN KEY (applied_by_admin_id) REFERENCES Admins(admin_id)
    );

    -- Index for better performance
    CREATE INDEX IX_UserTimelineControl_CitizenId ON UserTimelineControl (citizen_id);
    CREATE INDEX IX_UserTimelineControl_ControlType ON UserTimelineControl (control_type);
END
GO

-- Admin Action History Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'AdminActionHistory')
BEGIN
    CREATE TABLE AdminActionHistory
    (
        action_id INT IDENTITY(1,1) PRIMARY KEY,
        admin_id INT NOT NULL,
        target_citizen_id INT,
        target_grievance_id INT,
        action_type NVARCHAR(50) NOT NULL CHECK (action_type IN (
            'User_Suspend', 'User_Activate', 'Timeline_Control', 'Grievance_Assign',
            'Status_Change', 'Permission_Grant', 'Permission_Revoke', 'Data_Export',
            'Report_Generate', 'System_Config', 'Force_Logout'
        )),
        action_description NVARCHAR(500) NOT NULL,
        previous_value NVARCHAR(500),
        new_value NVARCHAR(500),
        ip_address NVARCHAR(45),
        session_id NVARCHAR(100),
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (admin_id) REFERENCES Admins(admin_id),
        FOREIGN KEY (target_citizen_id) REFERENCES Citizens(citizen_id),
        FOREIGN KEY (target_grievance_id) REFERENCES Grievances(grievance_id)
    );

    -- Index for better performance
    CREATE INDEX IX_AdminActionHistory_AdminId_CreatedAt ON AdminActionHistory (admin_id, created_at DESC);
    CREATE INDEX IX_AdminActionHistory_ActionType ON AdminActionHistory (action_type);
END
GO

-- User Session Tracking Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'UserSessions')
BEGIN
    CREATE TABLE UserSessions
    (
        session_id NVARCHAR(100) PRIMARY KEY,
        citizen_id INT NOT NULL,
        login_time DATETIME2 DEFAULT GETDATE(),
        last_activity DATETIME2 DEFAULT GETDATE(),
        logout_time DATETIME2,
        ip_address NVARCHAR(45),
        user_agent NVARCHAR(500),
        is_active BIT DEFAULT 1,
        force_logout BIT DEFAULT 0,
        logout_reason NVARCHAR(100),
        FOREIGN KEY (citizen_id) REFERENCES Citizens(citizen_id) ON DELETE CASCADE
    );

    -- Index for better performance
    CREATE INDEX IX_UserSessions_CitizenId_IsActive ON UserSessions (citizen_id, is_active);
    CREATE INDEX IX_UserSessions_LastActivity ON UserSessions (last_activity DESC);
END
GO

-- Stored Procedure: Log User Activity
CREATE OR ALTER PROCEDURE SP_LogUserActivity
    @citizen_id INT,
    @activity_type NVARCHAR(50),
    @activity_description NVARCHAR(500) = NULL,
    @ip_address NVARCHAR(45) = NULL,
    @user_agent NVARCHAR(500) = NULL,
    @session_id NVARCHAR(100) = NULL,
    @status NVARCHAR(20) = 'Success'
AS
BEGIN
    INSERT INTO UserActivityLogs
        (
        citizen_id, activity_type, activity_description,
        ip_address, user_agent, session_id, status
        )
    VALUES
        (
            @citizen_id, @activity_type, @activity_description,
            @ip_address, @user_agent, @session_id, @status
    );
END
GO

-- Stored Procedure: Apply Timeline Control
CREATE OR ALTER PROCEDURE SP_ApplyTimelineControl
    @citizen_id INT,
    @control_type NVARCHAR(50),
    @reason NVARCHAR(500),
    @applied_by_admin_id INT,
    @end_date DATETIME2 = NULL,
    @notes NVARCHAR(1000) = NULL
AS
BEGIN
    -- Deactivate existing controls of the same type
    UPDATE UserTimelineControl 
    SET is_active = 0, updated_at = GETDATE()
    WHERE citizen_id = @citizen_id AND control_type = @control_type AND is_active = 1;

    -- Insert new control
    INSERT INTO UserTimelineControl
        (
        citizen_id, control_type, reason, applied_by_admin_id,
        end_date, notes
        )
    VALUES
        (
            @citizen_id, @control_type, @reason, @applied_by_admin_id,
            @end_date, @notes
    );

    -- Log admin action
    INSERT INTO AdminActionHistory
        (
        admin_id, target_citizen_id, action_type, action_description
        )
    VALUES
        (
            @applied_by_admin_id, @citizen_id, 'Timeline_Control',
            'Applied ' + @control_type + ' - ' + @reason
    );
END
GO

-- Stored Procedure: Remove Timeline Control
CREATE OR ALTER PROCEDURE SP_RemoveTimelineControl
    @citizen_id INT,
    @control_type NVARCHAR(50),
    @removed_by_admin_id INT,
    @removal_reason NVARCHAR(500) = 'Admin decision'
AS
BEGIN
    -- Deactivate the control
    UPDATE UserTimelineControl 
    SET is_active = 0, updated_at = GETDATE()
    WHERE citizen_id = @citizen_id AND control_type = @control_type AND is_active = 1;

    -- Log admin action
    INSERT INTO AdminActionHistory
        (
        admin_id, target_citizen_id, action_type, action_description
        )
    VALUES
        (
            @removed_by_admin_id, @citizen_id, 'Timeline_Control',
            'Removed ' + @control_type + ' - ' + @removal_reason
    );
END
GO

-- Stored Procedure: Get User Timeline
CREATE OR ALTER PROCEDURE SP_GetUserTimeline
    @citizen_id INT,
    @start_date DATETIME2 = NULL,
    @end_date DATETIME2 = NULL,
    @activity_type NVARCHAR(50) = NULL,
    @page_size INT = 50,
    @page_number INT = 1
AS
BEGIN
    SET @start_date = ISNULL(@start_date, DATEADD(MONTH, -3, GETDATE()));
    SET @end_date = ISNULL(@end_date, GETDATE());

    SELECT
        log_id,
        activity_type,
        activity_description,
        ip_address,
        status,
        created_at
    FROM UserActivityLogs
    WHERE citizen_id = @citizen_id
        AND created_at BETWEEN @start_date AND @end_date
        AND (@activity_type IS NULL OR activity_type = @activity_type)
    ORDER BY created_at DESC
    OFFSET (@page_number - 1) * @page_size ROWS
    FETCH NEXT @page_size ROWS ONLY;
END
GO

-- Stored Procedure: Get Active Timeline Controls
CREATE OR ALTER PROCEDURE SP_GetActiveTimelineControls
    @citizen_id INT = NULL
AS
BEGIN
    SELECT
        utc.control_id,
        utc.citizen_id,
        c.full_name,
        c.phone,
        c.email,
        utc.control_type,
        utc.start_date,
        utc.end_date,
        utc.reason,
        utc.notes,
        a.full_name as admin_name,
        utc.created_at
    FROM UserTimelineControl utc
        INNER JOIN Citizens c ON utc.citizen_id = c.citizen_id
        INNER JOIN Admins a ON utc.applied_by_admin_id = a.admin_id
    WHERE utc.is_active = 1
        AND (utc.end_date IS NULL OR utc.end_date > GETDATE())
        AND (@citizen_id IS NULL OR utc.citizen_id = @citizen_id)
    ORDER BY utc.created_at DESC;
END
GO

-- Stored Procedure: Force User Logout
CREATE OR ALTER PROCEDURE SP_ForceUserLogout
    @citizen_id INT,
    @admin_id INT,
    @reason NVARCHAR(100) = 'Admin action'
AS
BEGIN
    -- Update active sessions
    UPDATE UserSessions 
    SET 
        force_logout = 1,
        logout_reason = @reason,
        logout_time = GETDATE(),
        is_active = 0
    WHERE citizen_id = @citizen_id AND is_active = 1;

    -- Log admin action
    INSERT INTO AdminActionHistory
        (
        admin_id, target_citizen_id, action_type, action_description
        )
    VALUES
        (
            @admin_id, @citizen_id, 'Force_Logout',
            'Forced logout: ' + @reason
    );

    -- Log user activity
    DECLARE @logout_description NVARCHAR(500) = 'Force logout by admin: ' + @reason;
    EXEC SP_LogUserActivity 
        @citizen_id = @citizen_id,
        @activity_type = 'Logout',
        @activity_description = @logout_description,
        @status = 'Forced';
END
GO

PRINT 'User Timeline Control System created successfully!';
