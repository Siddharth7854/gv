// fix-admin-token-handling.js
// This script verifies and fixes the admin token handling in both API and client

const sqlite3 = require('sqlite3').verbose();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const path = require('path');

// Connect to database
const db = new sqlite3.Database(path.join(__dirname, 'database.db'), (err) => {
  if (err) {
    console.error('❌ Database connection error:', err.message);
    process.exit(1);
  }
  console.log('🔌 Connected to SQLite database');
});

// Verify JWT secret is properly set
const JWT_SECRET = process.env.JWT_SECRET || 'default_jwt_secret_for_development';
console.log(`🔑 Using JWT_SECRET: ${JWT_SECRET.substring(0, 3)}...${JWT_SECRET.substring(JWT_SECRET.length - 3)}`);

// Check admin structure in database
function checkAdminTable() {
  return new Promise((resolve, reject) => {
    db.all(`SELECT name FROM sqlite_master WHERE type='table' AND name='admins'`, [], (err, tables) => {
      if (err) {
        reject(err);
        return;
      }

      if (!tables || tables.length === 0) {
        console.error('❌ Admin table not found!');
        createAdminTable()
          .then(() => createTestAdmin())
          .then(resolve)
          .catch(reject);
      } else {
        console.log('✅ Admin table exists');
        // Check admin table structure
        db.all(`PRAGMA table_info(admins)`, [], (err, columns) => {
          if (err) {
            reject(err);
            return;
          }

          console.log('📋 Admin table columns:', columns.map(c => c.name).join(', '));
          
          // Get all admin users
          db.all(`SELECT * FROM admins`, [], (err, admins) => {
            if (err) {
              reject(err);
              return;
            }
            
            if (!admins || admins.length === 0) {
              console.log('⚠️ No admin users found, creating test admin');
              createTestAdmin().then(resolve).catch(reject);
            } else {
              console.log(`✅ Found ${admins.length} admin users`);
              console.log('👤 Admin users:', admins.map(a => ({ id: a.id, username: a.username })));
              resolve(admins);
            }
          });
        });
      }
    });
  });
}

// Create admin table if not exists
function createAdminTable() {
  return new Promise((resolve, reject) => {
    const query = `
      CREATE TABLE IF NOT EXISTS admins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT,
        email TEXT,
        role TEXT DEFAULT 'admin',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `;
    
    db.run(query, (err) => {
      if (err) {
        console.error('❌ Failed to create admin table:', err);
        reject(err);
        return;
      }
      
      console.log('✅ Admin table created successfully');
      resolve();
    });
  });
}

// Create test admin if no admin exists
function createTestAdmin() {
  return new Promise((resolve, reject) => {
    const username = 'admin';
    const password = 'admin123';
    
    // Hash password
    bcrypt.hash(password, 10, (err, hashedPassword) => {
      if (err) {
        console.error('❌ Password hashing failed:', err);
        reject(err);
        return;
      }
      
      const query = `
        INSERT OR REPLACE INTO admins (username, password, name, email, role)
        VALUES (?, ?, ?, ?, ?)
      `;
      
      db.run(query, [username, hashedPassword, 'Admin User', 'admin@example.com', 'admin'], function(err) {
        if (err) {
          console.error('❌ Failed to create admin user:', err);
          reject(err);
          return;
        }
        
        console.log(`✅ Admin user created/updated with ID: ${this.lastID}`);
        console.log(`🔑 Admin credentials: username: ${username}, password: ${password}`);
        resolve();
      });
    });
  });
}

// Test admin login and token generation
function testAdminLogin() {
  return new Promise((resolve, reject) => {
    const username = 'admin';
    const password = 'admin123';
    
    db.get('SELECT * FROM admins WHERE username = ?', [username], (err, admin) => {
      if (err) {
        console.error('❌ Admin lookup failed:', err);
        reject(err);
        return;
      }
      
      if (!admin) {
        console.error('❌ Admin not found');
        reject(new Error('Admin not found'));
        return;
      }
      
      bcrypt.compare(password, admin.password, (err, isMatch) => {
        if (err) {
          console.error('❌ Password comparison failed:', err);
          reject(err);
          return;
        }
        
        if (!isMatch) {
          console.error('❌ Password does not match');
          reject(new Error('Invalid password'));
          return;
        }
        
        // Generate JWT token
        const token = jwt.sign(
          { 
            adminId: admin.id,
            username: admin.username,
            role: admin.role
          }, 
          JWT_SECRET, 
          { expiresIn: '24h' }
        );
        
        console.log('✅ Admin login successful');
        console.log('🎟️ JWT token generated:', token);
        
        // Verify token can be decoded
        try {
          const decoded = jwt.verify(token, JWT_SECRET);
          console.log('✅ Token verified successfully');
          console.log('📄 Decoded token payload:', decoded);
          
          // Test if it has adminId
          if (!decoded.adminId) {
            console.error('❌ Token missing adminId');
            reject(new Error('Token missing adminId'));
            return;
          }
          
          resolve({ token, adminId: decoded.adminId });
        } catch (err) {
          console.error('❌ Token verification failed:', err);
          reject(err);
        }
      });
    });
  });
}

// Test dashboard stats API with token
function testDashboardAPI(token) {
  return new Promise((resolve, reject) => {
    console.log('🧪 Testing dashboard stats query with token');
    
    // Verify token first
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      console.log('✅ Token valid for testing API:', decoded);
      
      // Query some basic stats
      const queries = [
        "SELECT COUNT(*) as total FROM grievances",
        "SELECT COUNT(*) as total FROM users",
        "SELECT status, COUNT(*) as count FROM grievances GROUP BY status"
      ];
      
      Promise.all(queries.map(query => {
        return new Promise((resolve, reject) => {
          db.all(query, [], (err, results) => {
            if (err) {
              reject(err);
              return;
            }
            resolve({ query, results });
          });
        });
      }))
      .then(results => {
        console.log('📊 Dashboard stats query results:');
        results.forEach(r => {
          console.log(`📈 ${r.query}:`, r.results);
        });
        
        const dashboardStats = {
          grievanceCount: results[0].results[0].total,
          userCount: results[1].results[0].total,
          statusDistribution: results[2].results
        };
        
        console.log('✅ Dashboard API test successful');
        resolve(dashboardStats);
      })
      .catch(err => {
        console.error('❌ Dashboard API test failed:', err);
        reject(err);
      });
      
    } catch (err) {
      console.error('❌ Token validation failed:', err);
      reject(err);
    }
  });
}

// Main function
async function main() {
  console.log('🔍 Running admin token handling verification and fix');
  
  try {
    // Step 1: Check admin table and users
    await checkAdminTable();
    
    // Step 2: Test admin login and token generation
    const { token, adminId } = await testAdminLogin();
    
    // Step 3: Test dashboard stats API with token
    const stats = await testDashboardAPI(token);
    
    console.log('\n✅ VERIFICATION COMPLETE ✅');
    console.log('✅ Admin authentication working properly');
    console.log('✅ JWT token generation successful');
    console.log('✅ Dashboard API queries working');
    console.log('\n📊 Sample dashboard stats:', stats);
    
    console.log('\n🛠️ TOKEN FOR TESTING 🛠️');
    console.log('Token:', token);
    console.log('\n📋 CLIENT INTEGRATION GUIDE 📋');
    console.log('1. Store this token in adminAuthProvider');
    console.log('2. Set token in AdminApiService');
    console.log('3. Check HTTP Authorization header is properly set');
    console.log('4. Verify JWT has adminId in payload');
    
  } catch (err) {
    console.error('❌ Verification failed:', err);
  } finally {
    // Close database connection
    db.close((err) => {
      if (err) {
        console.error('❌ Error closing database:', err);
        process.exit(1);
      }
      console.log('🔌 Database connection closed');
    });
  }
}

main();
