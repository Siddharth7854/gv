const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const path = require('path');

async function testPasswordMatching() {
  console.log('🔍 Testing Password Matching for Login...\n');
  
  const dbPath = path.join(__dirname, 'data', 'grievance.db');
  const db = new sqlite3.Database(dbPath);
  
  // Get user with phone 9876543210
  db.get("SELECT * FROM users WHERE phoneNumber = ?", ['9876543210'], async (err, user) => {
    if (err) {
      console.log('❌ Error:', err.message);
      return;
    }
    
    if (!user) {
      console.log('❌ User not found');
      return;
    }
    
    console.log('✅ User found:', user.fullName);
    console.log('📱 Phone:', user.phoneNumber);
    console.log('🔐 Stored password hash:', user.password.substring(0, 20) + '...');
    
    // Test different passwords
    const testPasswords = ['password123', 'flutter123', 'test123', 'admin123'];
    
    console.log('\n🔍 Testing passwords...');
    for (const testPassword of testPasswords) {
      try {
        const isMatch = await bcrypt.compare(testPassword, user.password);
        console.log(`   "${testPassword}": ${isMatch ? '✅ MATCH' : '❌ NO MATCH'}`);
        
        if (isMatch) {
          console.log(`\n🎉 CORRECT PASSWORD FOUND: "${testPassword}"`);
          console.log('📱 Use these credentials in Flutter:');
          console.log(`   Phone: ${user.phoneNumber}`);
          console.log(`   Password: ${testPassword}`);
          break;
        }
      } catch (error) {
        console.log(`   "${testPassword}": ❌ ERROR - ${error.message}`);
      }
    }
    
    // If no match found, let's create a new test user with known password
    console.log('\n🔧 Creating fresh test user with known password...');
    const newPassword = 'test123';
    const hashedPassword = await bcrypt.hash(newPassword, 12);
    const userId = 'USER_FLUTTER_TEST_' + Date.now();
    
    db.run(`INSERT OR REPLACE INTO users 
      (userId, email, fullName, phoneNumber, password, role, isActive, createdAt, updatedAt) 
      VALUES (?, ?, ?, ?, ?, 'citizen', 1, datetime('now'), datetime('now'))`,
      [userId, 'flutter.test@example.com', 'Flutter Test User', '1234567890', hashedPassword],
      function(err) {
        if (err) {
          console.log('❌ Error creating test user:', err.message);
        } else {
          console.log('✅ Test user created successfully!');
          console.log('📱 Flutter Login Credentials:');
          console.log('   Phone: 1234567890');
          console.log('   Password: test123');
        }
        db.close();
      }
    );
  });
}

testPasswordMatching();
