-- Add Admin Table and Default Admin User
-- Date: July 27, 2025

USE GrievanceManagementDB;
GO

-- Admins Table
IF NOT EXISTS (SELECT *
FROM sys.tables
WHERE name = 'Admins')
BEGIN
    CREATE TABLE Admins
    (
        admin_id INT IDENTITY(1,1) PRIMARY KEY,
        username NVARCHAR(50) NOT NULL UNIQUE,
        email NVARCHAR(100) UNIQUE,
        full_name NVARCHAR(100) NOT NULL,
        password_hash NVARCHAR(255) NOT NULL,
        role NVARCHAR(50) NOT NULL DEFAULT 'admin',
        permissions NVARCHAR(MAX),
        -- JSON string for permissions
        is_active BIT DEFAULT 1,
        last_login DATETIME2,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        created_by INT
    );
END
GO

-- Insert Default Admin User
-- Password: admin123 (hashed with bcrypt)
IF NOT EXISTS (SELECT *
FROM Admins
WHERE username = 'admin')
BEGIN
    INSERT INTO Admins
        (username, email, full_name, password_hash, role, permissions)
    VALUES
        (
            'admin',
            'admin@grievance.gov.in',
            'System Administrator',
            '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- bcrypt hash for 'admin123'
            'super_admin',
            '{"dashboard": true, "grievances": true, "users": true, "analytics": true, "settings": true, "reports": true}'
    );
END
GO

-- Insert Additional Admin Users (optional)
IF NOT EXISTS (SELECT *
FROM Admins
WHERE username = 'supervisor')
BEGIN
    INSERT INTO Admins
        (username, email, full_name, password_hash, role, permissions)
    VALUES
        (
            'supervisor',
            'supervisor@grievance.gov.in',
            'Department Supervisor',
            '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- bcrypt hash for 'admin123'
            'supervisor',
            '{"dashboard": true, "grievances": true, "users": false, "analytics": true, "settings": false, "reports": true}'
    );
END
GO

PRINT 'Admin table and users created successfully!';
PRINT 'Default login credentials:';
PRINT 'Username: admin, Password: admin123';
PRINT 'Username: supervisor, Password: admin123';
