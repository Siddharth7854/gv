const { DatabaseService } = require('./config/database');

async function setupDatabase() {
  console.log('🚀 Starting complete database setup...');
  
  try {
    if (process.env.ENABLE_SQL_SERVER !== 'true') {
      console.log('ℹ️ SQL Server setup skipped: ENABLE_SQL_SERVER is not set to true.');
      console.log('   To enable, set ENABLE_SQL_SERVER=true in your environment and rerun.');
      return;
    }
    // Connect to database (this will auto-create tables)
    const dbService = new DatabaseService();
    await dbService.connect();
    
    console.log('✅ Database setup completed successfully!');
    console.log('');
    console.log('📋 Database Configuration:');
    console.log('   Server: DESKTOP-E2H6BA3\\SQLEXPRESS');
    console.log('   Database: GrievanceManagementDB');
    console.log('   User: sa');
    console.log('');
    console.log('📋 Tables Created:');
    console.log('   ✓ users - User authentication and profiles');
    console.log('   ✓ grievances - Grievance records and tracking');
    console.log('   ✓ admins - Admin user management');
    console.log('   ✓ chat_messages - Chat communication');
    console.log('   ✓ notifications - FCM and notification logs');
    console.log('   ✓ grievance_timeline - Activity tracking');
    console.log('');
    console.log('👤 Default Admin Created:');
    console.log('   Username: admin');
    console.log('   Password: admin123');
    console.log('   Email: admin@gov.in');
    console.log('');
    console.log('🎉 Ready to start the server!');
    
  } catch (error) {
    console.error('❌ Database setup failed:', error);
    process.exit(1);
  } finally {
    try {
      // dbService may not exist if skipped
      if (typeof dbService !== 'undefined' && dbService && dbService.disconnect) {
        await dbService.disconnect();
      }
    } catch {}
    process.exit(0);
  }
}

// Run setup if this file is executed directly
if (require.main === module) {
  setupDatabase();
}

module.exports = setupDatabase;
