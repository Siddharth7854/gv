const SQLiteService = require('./config/sqlite');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

async function createDefaultAdmin() {
  try {
    console.log('🛠️ Creating default admin user...');
    
    const dbService = new SQLiteService();
    await dbService.connect();
    
    // Check if admin already exists
    const existing = await dbService.query('SELECT adminId FROM admins WHERE username = ?', ['admin']);
    
    if (existing.length > 0) {
      console.log('✅ Admin user already exists, skipping creation');
      return;
    }
    
    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('admin123', salt);
    const adminId = uuidv4();
    
    // Create admin user
    await dbService.run(
      `INSERT INTO admins (adminId, username, password, email, fullName, role, isActive, createdAt) 
       VALUES (?, ?, ?, ?, ?, ?, 1, CURRENT_TIMESTAMP)`,
      [adminId, 'admin', hashedPassword, 'admin@system.com', 'System Administrator', 'super_admin']
    );
    
    console.log(`✅ Default admin created with ID: ${adminId}`);
    console.log('Username: admin');
    console.log('Password: admin123');
    
    await dbService.close();
    
  } catch (error) {
    console.error('❌ Failed to create default admin:', error);
    process.exit(1);
  }
}

createDefaultAdmin();
