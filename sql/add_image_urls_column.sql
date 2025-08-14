-- Add image_urls column to GrievanceStatusHistory table
-- This will store comma-separated list of image file paths for status updates

USE [grievance_system];

-- Check if column exists, if not add it
IF NOT EXISTS (
    SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'GrievanceStatusHistory'
    AND COLUMN_NAME = 'image_urls'
)
BEGIN
    ALTER TABLE GrievanceStatusHistory 
    ADD image_urls NVARCHAR(MAX) NULL;

    PRINT 'image_urls column added to GrievanceStatusHistory table successfully.';
END
ELSE
BEGIN
    PRINT 'image_urls column already exists in GrievanceStatusHistory table.';
END

-- Update existing records to have empty string instead of NULL for consistency
UPDATE GrievanceStatusHistory 
SET image_urls = '' 
WHERE image_urls IS NULL;

PRINT 'Database update completed successfully.';
