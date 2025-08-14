-- Government Grievance Management System - SQL Server Database Setup
-- Author: GitHub Copilot
-- Date: July 25, 2025

-- Create Database
IF NOT EXISTS (SELECT *
FROM sys.databases
WHERE name = 'GrievanceManagementDB')
BEGIN
    CREATE DATABASE GrievanceManagementDB;
END
GO

USE GrievanceManagementDB;
GO

-- Citizens Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'Citizens')
BEGIN
    CREATE TABLE Citizens
    (
        citizen_id INT IDENTITY(1,1) PRIMARY KEY,
        full_name NVARCHAR(100) NOT NULL,
        email NVARCHAR(100) UNIQUE,
        phone NVARCHAR(15) NOT NULL UNIQUE,
        aadhar_number NVARCHAR(12) NOT NULL UNIQUE,
        district NVARCHAR(50) NOT NULL,
        block NVARCHAR(50) NOT NULL,
        ward NVARCHAR(50) NOT NULL,
        address NVARCHAR(500) NOT NULL,
        pincode NVARCHAR(6) NOT NULL,
        password_hash NVARCHAR(255) NOT NULL,
        photo_url NVARCHAR(500) NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        is_active BIT DEFAULT 1
    );
END
GO

-- Categories Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'Categories')
BEGIN
    CREATE TABLE Categories
    (
        category_id INT IDENTITY(1,1) PRIMARY KEY,
        category_name NVARCHAR(100) NOT NULL UNIQUE,
        description NVARCHAR(500),
        is_active BIT DEFAULT 1,
        created_at DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Grievances Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'Grievances')
BEGIN
    CREATE TABLE Grievances
    (
        grievance_id INT IDENTITY(1,1) PRIMARY KEY,
        grievance_number NVARCHAR(50) NOT NULL UNIQUE,
        citizen_id INT NOT NULL,
        category_id INT NOT NULL,
        title NVARCHAR(200) NOT NULL,
        description NVARCHAR(MAX) NOT NULL,
        priority NVARCHAR(20) NOT NULL CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
        urgency NVARCHAR(20) NOT NULL CHECK (urgency IN ('Normal', 'Urgent', 'Emergency')),
        status NVARCHAR(30) NOT NULL DEFAULT 'Submitted' CHECK (status IN ('Submitted', 'Under Review', 'In Progress', 'Resolved', 'Closed', 'Rejected')),
        location_latitude DECIMAL(10, 8),
        location_longitude DECIMAL(11, 8),
        location_address NVARCHAR(500),
        submitted_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        resolved_at DATETIME2,
        assigned_to NVARCHAR(100),
        resolution_notes NVARCHAR(MAX),
        FOREIGN KEY (citizen_id) REFERENCES Citizens(citizen_id),
        FOREIGN KEY (category_id) REFERENCES Categories(category_id)
    );
END
GO

-- Media Attachments Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'MediaAttachments')
BEGIN
    CREATE TABLE MediaAttachments
    (
        attachment_id INT IDENTITY(1,1) PRIMARY KEY,
        grievance_id INT NOT NULL,
        file_name NVARCHAR(255) NOT NULL,
        file_path NVARCHAR(500) NOT NULL,
        file_type NVARCHAR(50) NOT NULL CHECK (file_type IN ('image', 'audio', 'video', 'document')),
        file_size BIGINT,
        mime_type NVARCHAR(100),
        uploaded_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (grievance_id) REFERENCES Grievances(grievance_id) ON DELETE CASCADE
    );
END
GO

-- Grievance Status History Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'GrievanceStatusHistory')
BEGIN
    CREATE TABLE GrievanceStatusHistory
    (
        history_id INT IDENTITY(1,1) PRIMARY KEY,
        grievance_id INT NOT NULL,
        previous_status NVARCHAR(30),
        new_status NVARCHAR(30) NOT NULL,
        changed_by NVARCHAR(100),
        change_reason NVARCHAR(500),
        changed_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (grievance_id) REFERENCES Grievances(grievance_id) ON DELETE CASCADE
    );
END
GO

-- Add photo_url column if it doesn't exist (for existing databases)
IF NOT EXISTS (SELECT *
FROM sys.columns
WHERE object_id = OBJECT_ID('Citizens') AND name = 'photo_url')
BEGIN
    ALTER TABLE Citizens ADD photo_url NVARCHAR(500) NULL;
    PRINT 'Added photo_url column to Citizens table';
END
GO

-- Insert Default Categories
IF NOT EXISTS (SELECT *
FROM Categories
WHERE category_name = 'Water Supply')
BEGIN
    INSERT INTO Categories
        (category_name, description)
    VALUES
        ('Water Supply', 'Issues related to water supply, quality, and distribution'),
        ('Electricity', 'Power outages, billing issues, and electrical infrastructure'),
        ('Roads & Transportation', 'Road conditions, traffic issues, and public transport'),
        ('Sanitation', 'Waste management, drainage, and cleanliness issues'),
        ('Healthcare', 'Medical facilities, services, and healthcare access'),
        ('Education', 'School infrastructure, teaching quality, and educational services'),
        ('Police & Law', 'Law enforcement, safety, and security concerns'),
        ('Municipal Services', 'Public services, civic amenities, and administrative issues'),
        ('Agricultural Issues', 'Farming support, irrigation, and agricultural policies'),
        ('Environmental Issues', 'Pollution, environmental protection, and green initiatives'),
        ('Other', 'Miscellaneous issues not covered in other categories');
END
GO

-- Create Indexes for Performance
CREATE NONCLUSTERED INDEX IX_Grievances_CitizenId ON Grievances(citizen_id);
CREATE NONCLUSTERED INDEX IX_Grievances_CategoryId ON Grievances(category_id);
CREATE NONCLUSTERED INDEX IX_Grievances_Status ON Grievances(status);
CREATE NONCLUSTERED INDEX IX_Grievances_SubmittedAt ON Grievances(submitted_at);
CREATE NONCLUSTERED INDEX IX_Citizens_Phone ON Citizens(phone);
CREATE NONCLUSTERED INDEX IX_Citizens_Email ON Citizens(email);
GO

-- Create Views for Common Queries
CREATE OR ALTER VIEW vw_GrievanceDetails
AS
    SELECT
        g.grievance_id,
        g.grievance_number,
        g.title,
        g.description,
        g.priority,
        g.urgency,
        g.status,
        g.location_latitude,
        g.location_longitude,
        g.location_address,
        g.submitted_at,
        g.updated_at,
        g.resolved_at,
        c.full_name AS citizen_name,
        c.phone AS citizen_phone,
        c.email AS citizen_email,
        c.district,
        c.block,
        c.ward,
        cat.category_name,
        cat.description AS category_description
    FROM Grievances g
        INNER JOIN Citizens c ON g.citizen_id = c.citizen_id
        INNER JOIN Categories cat ON g.category_id = cat.category_id;
GO

-- Create Stored Procedures
CREATE OR ALTER PROCEDURE sp_InsertGrievance
    @citizen_id INT,
    @category_id INT,
    @title NVARCHAR(200),
    @description NVARCHAR(MAX),
    @priority NVARCHAR(20),
    @urgency NVARCHAR(20),
    @location_latitude DECIMAL(10, 8) = NULL,
    @location_longitude DECIMAL(11, 8) = NULL,
    @location_address NVARCHAR(500) = NULL
AS
BEGIN
    DECLARE @grievance_number NVARCHAR(50);
    DECLARE @grievance_id INT;

    -- Generate unique grievance number
    SET @grievance_number = 'GRV' + FORMAT(GETDATE(), 'yyyyMMdd') + FORMAT(NEXT VALUE FOR seq_grievance_number, '0000');

    INSERT INTO Grievances
        (
        grievance_number, citizen_id, category_id, title, description,
        priority, urgency, location_latitude, location_longitude, location_address
        )
    VALUES
        (
            @grievance_number, @citizen_id, @category_id, @title, @description,
            @priority, @urgency, @location_latitude, @location_longitude, @location_address
    );

    SET @grievance_id = SCOPE_IDENTITY();

    -- Insert initial status history
    INSERT INTO GrievanceStatusHistory
        (grievance_id, new_status, changed_by, change_reason)
    VALUES
        (@grievance_id, 'Submitted', 'System', 'Initial submission');

    SELECT @grievance_id AS grievance_id, @grievance_number AS grievance_number;
END
GO

-- Create Sequence for Grievance Numbers
IF NOT EXISTS (SELECT *
FROM sys.sequences
WHERE name = 'seq_grievance_number')
BEGIN
    CREATE SEQUENCE seq_grievance_number
        START WITH 1
        INCREMENT BY 1
        MINVALUE 1
        MAXVALUE 9999
        CYCLE;
END
GO

-- Create Login/Authentication Procedure
CREATE OR ALTER PROCEDURE sp_AuthenticateUser
    @phone NVARCHAR(15),
    @password_hash NVARCHAR(255)
AS
BEGIN
    SELECT
        citizen_id,
        full_name,
        email,
        phone,
        district,
        block,
        ward,
        address,
        pincode,
        photo_url
    FROM Citizens
    WHERE phone = @phone
        AND password_hash = @password_hash
        AND is_active = 1;
END
GO

-- Create User Registration Procedure
CREATE OR ALTER PROCEDURE sp_RegisterCitizen
    @full_name NVARCHAR(100),
    @email NVARCHAR(100),
    @phone NVARCHAR(15),
    @aadhar_number NVARCHAR(12),
    @district NVARCHAR(50),
    @block NVARCHAR(50),
    @ward NVARCHAR(50),
    @address NVARCHAR(500),
    @pincode NVARCHAR(6),
    @password_hash NVARCHAR(255)
AS
BEGIN
    INSERT INTO Citizens
        (
        full_name, email, phone, aadhar_number, district,
        block, ward, address, pincode, password_hash
        )
    VALUES
        (
            @full_name, @email, @phone, @aadhar_number, @district,
            @block, @ward, @address, @pincode, @password_hash
    );

    SELECT SCOPE_IDENTITY() AS citizen_id;
END
GO

-- Create Profile Update Procedure
CREATE OR ALTER PROCEDURE sp_UpdateProfile
    @citizen_id INT,
    @full_name NVARCHAR(100) = NULL,
    @email NVARCHAR(100) = NULL,
    @district NVARCHAR(50) = NULL,
    @block NVARCHAR(50) = NULL,
    @ward NVARCHAR(50) = NULL,
    @address NVARCHAR(500) = NULL,
    @pincode NVARCHAR(6) = NULL,
    @photo_url NVARCHAR(500) = NULL
AS
BEGIN
    UPDATE Citizens 
    SET 
        full_name = ISNULL(@full_name, full_name),
        email = ISNULL(@email, email),
        district = ISNULL(@district, district),
        block = ISNULL(@block, block),
        ward = ISNULL(@ward, ward),
        address = ISNULL(@address, address),
        pincode = ISNULL(@pincode, pincode),
        photo_url = ISNULL(@photo_url, photo_url),
        updated_at = GETDATE()
    WHERE citizen_id = @citizen_id AND is_active = 1;

    SELECT @@ROWCOUNT AS rows_affected;
END
GO

-- Create Profile Photo Update Procedure
CREATE OR ALTER PROCEDURE sp_UpdateProfilePhoto
    @citizen_id INT,
    @photo_url NVARCHAR(500)
AS
BEGIN
    UPDATE Citizens 
    SET 
        photo_url = @photo_url,
        updated_at = GETDATE()
    WHERE citizen_id = @citizen_id AND is_active = 1;

    SELECT @@ROWCOUNT AS rows_affected;
END
GO

PRINT 'Database setup completed successfully!';
