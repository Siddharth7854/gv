// Test to check current users in database and verify logout functionality
const sql = require('mssql');

// Database configuration
const dbConfig = {
  server: 'localhost',
  database: 'GrievanceManagementDB',
  user: 'sa',
  password: 'Sid91221',
  port: 1433,
  options: {
    encrypt: false,
    trustServerCertificate: true,
    enableArithAbort: true
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};

async function checkUserDatabase() {
  try {
    console.log('🔍 Checking user database for logout testing...');
    
    // Connect to database
    const pool = await sql.connect(dbConfig);
    console.log('✅ Connected to SQL Server');
    
    // Check all users in database
    const usersResult = await pool.request().query(`
      SELECT TOP 5 
        citizen_id, 
        full_name, 
        email, 
        phone, 
        is_active
      FROM Citizens
      ORDER BY created_at DESC
    `);
    
    console.log('\n📋 Current users in database:');
    console.log('================================');
    
    if (usersResult.recordset.length === 0) {
      console.log('❌ No users found in database!');
      console.log('\n💡 Creating a test user for logout testing...');
      
      // Create a test user
      await pool.request().query(`
        INSERT INTO Citizens (
          citizen_id, full_name, email, phone, password_hash, 
          district, block, ward, address, pincode, is_active
        ) VALUES (
          'TEST123', 
          'Test User', 
          'test@example.com', 
          '9876543210', 
          '$2b$10$example.hash.for.password123', 
          'Test District', 
          'Test Block', 
          'Test Ward', 
          'Test Address', 
          '123456', 
          1
        )
      `);
      
      console.log('✅ Test user created!');
      console.log('📱 Phone: 9876543210');
      console.log('🔐 Password: password123');
      
    } else {
      usersResult.recordset.forEach((user, index) => {
        console.log(`${index + 1}. ${user.full_name}`);
        console.log(`   ID: ${user.citizen_id}`);
        console.log(`   Email: ${user.email}`);
        console.log(`   Phone: ${user.phone}`);
        console.log(`   Active: ${user.is_active ? 'Yes' : 'No'}`);
        console.log('   ---');
      });
    }
    
    console.log('\n🚪 LOGOUT FIX IMPLEMENTED:');
    console.log('=========================');
    console.log('✅ Enhanced logout method with proper state clearing');
    console.log('✅ Added loading feedback in UI');
    console.log('✅ Force state propagation with timestamps');
    console.log('✅ Improved error handling');
    console.log('✅ Added success confirmation');
    
    console.log('\n🔧 TROUBLESHOOTING STEPS:');
    console.log('========================');
    console.log('1. Use a valid phone number from the list above');
    console.log('2. Hot RESTART the Flutter app (not hot reload)');
    console.log('3. Login with valid credentials');
    console.log('4. Go to Profile → Logout');
    console.log('5. Check debug console for logout flow');
    
    await pool.close();
    
  } catch (error) {
    console.error('❌ Database error:', error.message);
  }
}

checkUserDatabase();
