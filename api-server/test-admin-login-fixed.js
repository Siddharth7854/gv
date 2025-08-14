// test-admin-login-fixed.js
// Integration test for admin login & dashboard functionality after fixes

const axios = require('axios');
const { promisify } = require('util');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const jwt = require('jsonwebtoken');

// Base URL for API
const BASE_URL = 'http://localhost:5000/api';
// Admin credentials
const ADMIN_USERNAME = 'admin';
const ADMIN_PASSWORD = 'admin123';

// Connect to SQLite database
const db = new sqlite3.Database(path.join(__dirname, 'database.db'));
// Promisify database operations
const dbGet = promisify(db.get.bind(db));
const dbAll = promisify(db.all.bind(db));
const dbRun = promisify(db.run.bind(db));

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'default_jwt_secret_for_development';

/**
 * Test admin login functionality
 */
async function testAdminLogin() {
  console.log('\n🔒 TESTING ADMIN LOGIN\n');
  
  try {
    console.log(`📤 Sending login request for admin: ${ADMIN_USERNAME}`);
    const response = await axios.post(`${BASE_URL}/admin/admin-login`, {
      username: ADMIN_USERNAME,
      password: ADMIN_PASSWORD
    });
    
    console.log('📥 Login response:', JSON.stringify(response.data, null, 2));
    
    // Verify response structure
    if (response.data.success !== true) {
      throw new Error('Login failed: ' + (response.data.error || 'Unknown error'));
    }
    
    if (!response.data.token) {
      throw new Error('Login response missing token');
    }
    
    // Verify token
    try {
      const decoded = jwt.verify(response.data.token, JWT_SECRET);
      console.log('✅ Token verified successfully');
      console.log('📄 Token payload:', decoded);
      
      if (!decoded.adminId) {
        throw new Error('Token missing adminId');
      }
    } catch (error) {
      throw new Error(`Invalid token: ${error.message}`);
    }
    
    console.log('✅ ADMIN LOGIN TEST: SUCCESS');
    return response.data.token;
  } catch (error) {
    console.error('❌ ADMIN LOGIN TEST: FAILED');
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('❌ Response:', error.response.data);
    }
    throw error;
  }
}

/**
 * Test dashboard stats API
 */
async function testDashboardStats(token) {
  console.log('\n📊 TESTING DASHBOARD STATS\n');
  
  try {
    console.log('📤 Sending dashboard stats request');
    const response = await axios.get(`${BASE_URL}/admin/dashboard-stats`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('📥 Dashboard response:', JSON.stringify(response.data, null, 2));
    
    // Verify response structure
    if (response.data.success !== true) {
      throw new Error('Dashboard stats failed: ' + (response.data.error || 'Unknown error'));
    }
    
    if (!response.data.data) {
      throw new Error('Dashboard response missing data');
    }
    
    // Verify data structure
    const stats = response.data.data;
    console.log('✅ Dashboard stats retrieved successfully');
    console.log(`📊 Total Grievances: ${stats.totalGrievances}`);
    console.log(`👥 Total Users: ${stats.userCount}`);
    console.log(`🟡 Pending Grievances: ${stats.pendingGrievances}`);
    console.log(`🟢 Resolved Grievances: ${stats.resolvedGrievances}`);
    
    console.log('✅ DASHBOARD STATS TEST: SUCCESS');
    return stats;
  } catch (error) {
    console.error('❌ DASHBOARD STATS TEST: FAILED');
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('❌ Response:', error.response.data);
    }
    throw error;
  }
}

/**
 * Test grievances API
 */
async function testGrievances(token) {
  console.log('\n📝 TESTING GRIEVANCES API\n');
  
  try {
    console.log('📤 Sending grievances request');
    const response = await axios.get(`${BASE_URL}/admin/grievances`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('📥 Grievances response: ' + 
      `${response.data.success ? 'SUCCESS' : 'FAILED'} ` + 
      `(${response.data.data?.grievances?.length || 0} records)`);
    
    // Verify response structure
    if (response.data.success !== true) {
      throw new Error('Grievances API failed: ' + (response.data.error || 'Unknown error'));
    }
    
    if (!response.data.data || !response.data.data.grievances) {
      throw new Error('Grievances response missing data');
    }
    
    const { grievances, pagination } = response.data.data;
    console.log('✅ Grievances retrieved successfully');
    console.log(`📝 Retrieved ${grievances.length} grievances`);
    console.log(`📄 Pagination: Page ${pagination.page} of ${pagination.pages}, ` +
      `Total: ${pagination.total}, Limit: ${pagination.limit}`);
    
    if (grievances.length > 0) {
      console.log('📄 First grievance:', {
        id: grievances[0].id,
        title: grievances[0].title,
        status: grievances[0].status,
      });
    }
    
    console.log('✅ GRIEVANCES API TEST: SUCCESS');
    return grievances;
  } catch (error) {
    console.error('❌ GRIEVANCES API TEST: FAILED');
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('❌ Response:', error.response.data);
    }
    throw error;
  }
}

/**
 * Test users API
 */
async function testUsers(token) {
  console.log('\n👥 TESTING USERS API\n');
  
  try {
    console.log('📤 Sending users request');
    const response = await axios.get(`${BASE_URL}/admin/users`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('📥 Users response: ' + 
      `${response.data.success ? 'SUCCESS' : 'FAILED'} ` + 
      `(${response.data.data?.users?.length || 0} records)`);
    
    // Verify response structure
    if (response.data.success !== true) {
      throw new Error('Users API failed: ' + (response.data.error || 'Unknown error'));
    }
    
    if (!response.data.data || !response.data.data.users) {
      throw new Error('Users response missing data');
    }
    
    const { users, pagination } = response.data.data;
    console.log('✅ Users retrieved successfully');
    console.log(`👥 Retrieved ${users.length} users`);
    console.log(`📄 Pagination: Page ${pagination.page} of ${pagination.pages}, ` +
      `Total: ${pagination.total}, Limit: ${pagination.limit}`);
    
    if (users.length > 0) {
      console.log('👤 First user:', {
        id: users[0].id,
        name: users[0].name,
        email: users[0].email,
      });
    }
    
    console.log('✅ USERS API TEST: SUCCESS');
    return users;
  } catch (error) {
    console.error('❌ USERS API TEST: FAILED');
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('❌ Response:', error.response.data);
    }
    throw error;
  }
}

/**
 * Verify database structure
 */
async function verifyDatabase() {
  console.log('\n🔍 VERIFYING DATABASE STRUCTURE\n');
  
  try {
    // Check tables
    const tables = await dbAll("SELECT name FROM sqlite_master WHERE type='table'");
    console.log('📋 Tables:', tables.map(t => t.name).join(', '));
    
    // Check admins table
    const adminTable = tables.find(t => t.name === 'admins');
    if (!adminTable) {
      throw new Error('Admin table not found in database');
    }
    
    // Check admin table columns
    const adminColumns = await dbAll("PRAGMA table_info(admins)");
    console.log('📋 Admin table columns:', adminColumns.map(c => c.name).join(', '));
    
    // Check admin user
    const admin = await dbGet("SELECT * FROM admins WHERE username = ?", [ADMIN_USERNAME]);
    if (!admin) {
      throw new Error('Admin user not found in database');
    }
    
    console.log('✅ Admin user exists:', {
      id: admin.id,
      username: admin.username,
    });
    
    console.log('✅ DATABASE VERIFICATION: SUCCESS');
  } catch (error) {
    console.error('❌ DATABASE VERIFICATION: FAILED');
    console.error('❌ Error:', error.message);
    throw error;
  }
}

/**
 * Main test function
 */
async function runTests() {
  console.log('\n🚀 STARTING ADMIN LOGIN INTEGRATION TESTS\n');
  
  try {
    // Step 1: Verify database structure
    await verifyDatabase();
    
    // Step 2: Test admin login
    const token = await testAdminLogin();
    
    // Step 3: Test dashboard stats API
    await testDashboardStats(token);
    
    // Step 4: Test grievances API
    await testGrievances(token);
    
    // Step 5: Test users API
    await testUsers(token);
    
    console.log('\n✅ ALL TESTS PASSED ✅\n');
    console.log('📝 Test Results:');
    console.log('- Admin login: ✅ SUCCESS');
    console.log('- Dashboard stats: ✅ SUCCESS');
    console.log('- Grievances API: ✅ SUCCESS');
    console.log('- Users API: ✅ SUCCESS');
    console.log('\nFlutter app can now connect to the admin APIs successfully');
  } catch (error) {
    console.error('\n❌ TESTS FAILED ❌\n');
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    // Close database connection
    db.close();
  }
}

// Run tests
runTests();
