const sqlite3 = require('sqlite3').verbose();
const path = require('path');

async function checkDatabase() {
  console.log('🔍 Checking SQLite Database Connection & Data...\n');
  
  const dbPath = path.join(__dirname, 'data', 'grievance.db');
  console.log('📁 Database Path:', dbPath);
  
  const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
      console.log('❌ Database connection failed:', err.message);
      return;
    }
    console.log('✅ Connected to SQLite database\n');
  });

  // Check tables
  console.log('📋 Checking database tables...');
  db.all("SELECT name FROM sqlite_master WHERE type='table'", (err, tables) => {
    if (err) {
      console.log('❌ Error fetching tables:', err.message);
      return;
    }
    console.log('✅ Tables found:', tables.map(t => t.name));
    
    // Check users table structure
    console.log('\n🔍 Checking users table structure...');
    db.all("PRAGMA table_info(users)", (err, columns) => {
      if (err) {
        console.log('❌ Error checking table structure:', err.message);
        return;
      }
      console.log('📊 Users table columns:');
      columns.forEach(col => {
        console.log(`   ${col.name}: ${col.type}`);
      });
      
      // Check existing users
      console.log('\n👥 Checking existing users...');
      db.all("SELECT userId, fullName, email, phoneNumber, role FROM users", (err, users) => {
        if (err) {
          console.log('❌ Error fetching users:', err.message);
          return;
        }
        console.log(`✅ Found ${users.length} users:`);
        users.forEach(user => {
          console.log(`   📱 ${user.phoneNumber} - ${user.fullName} (${user.email})`);
        });
        
        // Test specific user
        console.log('\n🔍 Testing user with phone 9876543210...');
        db.get("SELECT * FROM users WHERE phoneNumber = ?", ['9876543210'], (err, user) => {
          if (err) {
            console.log('❌ Error:', err.message);
          } else if (user) {
            console.log('✅ User found:', {
              userId: user.userId,
              fullName: user.fullName,
              email: user.email,
              phoneNumber: user.phoneNumber,
              passwordExists: user.password ? 'YES' : 'NO',
              isActive: user.isActive
            });
          } else {
            console.log('❌ User with phone 9876543210 not found');
          }
          
          db.close();
        });
      });
    });
  });
}

checkDatabase();
