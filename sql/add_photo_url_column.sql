-- Add photo_url column if it doesn't exist (for existing databases)
USE GrievanceManagementDB;

IF NOT EXISTS (SELECT *
FROM sys.columns
WHERE object_id = OBJECT_ID('Citizens') AND name = 'photo_url')
BEGIN
    ALTER TABLE Citizens ADD photo_url NVARCHAR(500) NULL;
    PRINT 'Added photo_url column to Citizens table';
END
ELSE
BEGIN
    PRINT 'photo_url column already exists in Citizens table';
END
GO

-- Verify the column was added
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Citizens'
ORDER BY ORDINAL_POSITION;
