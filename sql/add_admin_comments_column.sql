-- Add admin_comments column to grievances table
USE GrievanceManagementDB;
GO

-- Check if admin_comments column exists, if not add it
IF NOT EXISTS (
    SELECT *
FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.grievances')
    AND name = 'admin_comments'
)
BEGIN
    ALTER TABLE grievances 
    ADD admin_comments NVARCHAR(MAX) NULL;
    PRINT 'admin_comments column added successfully to grievances table';
END
ELSE
BEGIN
    PRINT 'admin_comments column already exists in grievances table';
END
GO
