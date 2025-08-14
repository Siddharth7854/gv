@echo off
echo -----------------------------------------------------
echo  ADMIN PANEL FIXED SERVER - RUNNING IN FIXED MODE
echo -----------------------------------------------------
echo.
echo This script starts the API server with all the fixes applied for:
echo  1. Admin login functionality
echo  2. Table name case sensitivity fixes for SQLite
echo  3. JWT token handling with proper adminId
echo  4. Dashboard, grievances, and users APIs
echo.
echo Default admin credentials:
echo  - Username: admin
echo  - Password: admin123
echo.

echo Starting API server on port 5000...
cd /d %~dp0
node fix-admin-login-freeze.js
