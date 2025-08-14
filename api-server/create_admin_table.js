const SQLiteService = require('./config/sqlite');
const bcrypt = require('bcryptjs');

(async () => {
  try {
    const dbService = new SQLiteService();
    await dbService.connect();
    console.log('✅ SQLite connected');
    
    // Check if Admins table exists
    const tables = await dbService.query(`SELECT name FROM sqlite_master WHERE type='table' AND name='Admins'`);
    console.log('Admins table check:', tables);
    
    // Check existing admins directly
    let admins = [];
    try {
      admins = await dbService.query('SELECT * FROM Admins');
      console.log('✅ Admins table exists, found', admins.length, 'admins');
    } catch (error) {
      console.log('❌ Admins table does not exist, creating...');
      // Create Admins table
      await dbService.run(`
        CREATE TABLE Admins (
          admin_id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          email TEXT UNIQUE NOT NULL,
          full_name TEXT NOT NULL,
          password_hash TEXT NOT NULL,
          role TEXT DEFAULT 'admin',
          permissions TEXT DEFAULT '{}',
          is_active BOOLEAN DEFAULT 1,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          last_login DATETIME
        )
      `);
      console.log('✅ Admins table created');
      admins = [];
    }
    console.log('Existing admins:', admins.length);
    
    // Create default admin if no admin exists
    if (admins.length === 0) {
      console.log('Creating default admin...');
      const hashedPassword = await bcrypt.hash('admin123', 10);
      
      await dbService.run(`
        INSERT INTO Admins (adminId, username, email, fullName, password, role, department, isActive)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `, ['admin001', 'admin', 'admin@grievance.gov.in', 'System Administrator', hashedPassword, 'super_admin', 'IT Department', 1]);
      
      console.log('✅ Default admin created:');
      console.log('   Username: admin');
      console.log('   Password: admin123');
      console.log('   Email: admin@grievance.gov.in');
    }
    
    // Show all admins
    const finalAdmins = await dbService.query('SELECT adminId, username, email, fullName, role FROM Admins');
    console.log('\n📋 All Admins:');
    finalAdmins.forEach(admin => {
      console.log(`   ID: ${admin.adminId}, Username: ${admin.username}, Email: ${admin.email}, Role: ${admin.role}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
})();
