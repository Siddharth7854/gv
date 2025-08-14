-- Fix CHECK constraints for Timeline Control System
-- Date: August 1, 2025

USE GrievanceManagementDB;
GO

-- First, let's check the current constraint names
PRINT 'Checking existing constraints...';

-- Find AdminActionHistory action_type constraint
SELECT
    CONSTRAINT_NAME,
    CHECK_CLAUSE
FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS
WHERE TABLE_NAME = 'AdminActionHistory'
    AND COLUMN_NAME = 'action_type';

-- Find UserActivityLogs status constraint  
SELECT
    CONSTRAINT_NAME,
    CHECK_CLAUSE
FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS
WHERE TABLE_NAME = 'UserActivityLogs'
    AND COLUMN_NAME = 'status';

-- Drop and recreate AdminActionHistory action_type constraint
DECLARE @AdminConstraintName NVARCHAR(128);
SELECT @AdminConstraintName = CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS
WHERE TABLE_NAME = 'AdminActionHistory'
    AND CHECK_CLAUSE LIKE '%action_type%';

IF @AdminConstraintName IS NOT NULL
BEGIN
    DECLARE @AdminDropSQL NVARCHAR(500) = 'ALTER TABLE AdminActionHistory DROP CONSTRAINT ' + @AdminConstraintName;
    EXEC sp_executesql @AdminDropSQL;
    PRINT 'Dropped AdminActionHistory constraint: ' + @AdminConstraintName;
END

-- Add new AdminActionHistory constraint with Force_Logout
ALTER TABLE AdminActionHistory 
ADD CONSTRAINT CK_AdminActionHistory_ActionType 
CHECK (action_type IN (
    'User_Suspend', 'User_Activate', 'Timeline_Control', 'Grievance_Assign',
    'Status_Change', 'Permission_Grant', 'Permission_Revoke', 'Data_Export',
    'Report_Generate', 'System_Config', 'Force_Logout'
));
PRINT 'Added new AdminActionHistory constraint with Force_Logout';

-- Drop and recreate UserActivityLogs status constraint
DECLARE @UserConstraintName NVARCHAR(128);
SELECT @UserConstraintName = CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS
WHERE TABLE_NAME = 'UserActivityLogs'
    AND CHECK_CLAUSE LIKE '%status%';

IF @UserConstraintName IS NOT NULL
BEGIN
    DECLARE @UserDropSQL NVARCHAR(500) = 'ALTER TABLE UserActivityLogs DROP CONSTRAINT ' + @UserConstraintName;
    EXEC sp_executesql @UserDropSQL;
    PRINT 'Dropped UserActivityLogs constraint: ' + @UserConstraintName;
END

-- Add new UserActivityLogs constraint with Forced
ALTER TABLE UserActivityLogs 
ADD CONSTRAINT CK_UserActivityLogs_Status 
CHECK (status IN ('Success', 'Failed', 'Blocked', 'Forced'));
PRINT 'Added new UserActivityLogs constraint with Forced';

PRINT 'Timeline control constraints fixed successfully!';
