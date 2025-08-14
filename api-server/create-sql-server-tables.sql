-- SQL Server Tables Creation Script for Grievance Management System
USE GrievanceManagementDB;
GO

-- Users Table
CREATE TABLE users (
    userId NVARCHAR(50) PRIMARY KEY,
    email NVARCHAR(255) UNIQUE NOT NULL,
    fullName NVARCHAR(255) NOT NULL,
    phoneNumber NVARCHAR(20) NOT NULL,
    password NVARCHAR(255) NOT NULL,
    role NVARCHAR(50) DEFAULT 'citizen',
    isActive BIT DEFAULT 1,
    createdAt DATETIME2 DEFAULT GETDATE(),
    updatedAt DATETIME2 DEFAULT GETDATE(),
    photoUrl NVARCHAR(500),
    fcmToken NVARCHAR(500)
);
GO

-- Grievances Table  
CREATE TABLE grievances (
    grievanceId NVARCHAR(50) PRIMARY KEY,
    userId NVARCHAR(50) NOT NULL,
    title NVARCHAR(255) NOT NULL,
    description NTEXT NOT NULL,
    category NVARCHAR(100) NOT NULL,
    priority NVARCHAR(20) DEFAULT 'medium',
    status NVARCHAR(20) DEFAULT 'pending',
    assignedTo NVARCHAR(50),
    createdAt DATETIME2 DEFAULT GETDATE(),
    updatedAt DATETIME2 DEFAULT GETDATE(),
    resolvedAt DATETIME2,
    photoUrl NVARCHAR(500),
    adminComments NTEXT,
    FOREIGN KEY (userId) REFERENCES users(userId)
);
GO

-- Admins Table
CREATE TABLE admins (
    adminId NVARCHAR(50) PRIMARY KEY,
    username NVARCHAR(100) UNIQUE NOT NULL,
    email NVARCHAR(255) UNIQUE NOT NULL,
    fullName NVARCHAR(255) NOT NULL,
    password NVARCHAR(255) NOT NULL,
    role NVARCHAR(50) DEFAULT 'admin',
    department NVARCHAR(100),
    isActive BIT DEFAULT 1,
    createdAt DATETIME2 DEFAULT GETDATE(),
    lastLogin DATETIME2,
    fcmToken NVARCHAR(500)
);
GO

-- Chat Messages Table
CREATE TABLE chat_messages (
    messageId NVARCHAR(50) PRIMARY KEY,
    grievanceId NVARCHAR(50) NOT NULL,
    senderId NVARCHAR(50) NOT NULL,
    senderType NVARCHAR(20) NOT NULL,
    message NTEXT NOT NULL,
    messageType NVARCHAR(20) DEFAULT 'text',
    createdAt DATETIME2 DEFAULT GETDATE(),
    isRead BIT DEFAULT 0,
    FOREIGN KEY (grievanceId) REFERENCES grievances(grievanceId)
);
GO

-- Notifications Table
CREATE TABLE notifications (
    notificationId NVARCHAR(50) PRIMARY KEY,
    userId NVARCHAR(50) NOT NULL,
    title NVARCHAR(255) NOT NULL,
    message NTEXT NOT NULL,
    type NVARCHAR(50) NOT NULL,
    isRead BIT DEFAULT 0,
    createdAt DATETIME2 DEFAULT GETDATE(),
    data NTEXT,
    FOREIGN KEY (userId) REFERENCES users(userId)
);
GO

-- Timeline Table
CREATE TABLE timeline (
    timelineId NVARCHAR(50) PRIMARY KEY,
    grievanceId NVARCHAR(50) NOT NULL,
    action NVARCHAR(255) NOT NULL,
    description NTEXT NOT NULL,
    performedBy NVARCHAR(50) NOT NULL,
    performedByType NVARCHAR(20) NOT NULL,
    createdAt DATETIME2 DEFAULT GETDATE(),
    metadata NTEXT,
    FOREIGN KEY (grievanceId) REFERENCES grievances(grievanceId)
);
GO

-- Insert a default admin user
INSERT INTO admins (adminId, username, email, fullName, password, role, department, isActive)
VALUES (
    'ADMIN_DEFAULT_001',
    'admin',
    'admin@grievance.gov.in',
    'System Administrator',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyKa5DKM2N5ZWi', -- admin123
    'admin',
    'IT Department',
    1
);
GO

PRINT 'All tables created successfully!';
PRINT 'Default admin user created with username: admin, password: admin123';
GO
