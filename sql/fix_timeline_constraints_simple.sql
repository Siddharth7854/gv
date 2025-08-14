-- Fix CHECK constraints for Timeline Control System (Simple approach)
-- Date: August 1, 2025

USE GrievanceManagementDB;
GO

-- Find and drop existing constraints
DECLARE @sql NVARCHAR(MAX) = '';

-- Drop AdminActionHistory constraint
SELECT @sql = 'ALTER TABLE AdminActionHistory DROP CONSTRAINT ' + name
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('AdminActionHistory')
    AND definition LIKE '%action_type%';

IF @sql != ''
BEGIN
    EXEC sp_executesql @sql;
    PRINT 'Dropped AdminActionHistory action_type constraint';
END

-- Drop UserActivityLogs constraint
SET @sql = '';
SELECT @sql = 'ALTER TABLE UserActivityLogs DROP CONSTRAINT ' + name
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('UserActivityLogs')
    AND definition LIKE '%status%';

IF @sql != ''
BEGIN
    EXEC sp_executesql @sql;
    PRINT 'Dropped UserActivityLogs status constraint';
END

-- Add new constraints
ALTER TABLE AdminActionHistory 
ADD CONSTRAINT CK_AdminActionHistory_ActionType 
CHECK (action_type IN (
    'User_Suspend', 'User_Activate', 'Timeline_Control', 'Grievance_Assign',
    'Status_Change', 'Permission_Grant', 'Permission_Revoke', 'Data_Export',
    'Report_Generate', 'System_Config', 'Force_Logout'
));
PRINT 'Added new AdminActionHistory constraint with Force_Logout';

ALTER TABLE UserActivityLogs 
ADD CONSTRAINT CK_UserActivityLogs_Status 
CHECK (status IN ('Success', 'Failed', 'Blocked', 'Forced'));
PRINT 'Added new UserActivityLogs constraint with Forced';

PRINT 'Timeline control constraints fixed successfully!';
