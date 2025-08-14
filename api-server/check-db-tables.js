const SQLiteService = require('./config/sqlite'); 
const dbService = new SQLiteService(); 

async function checkTables() { 
  try { 
    await dbService.connect(); 
    const result = await dbService.query('SELECT name FROM sqlite_master WHERE type=\'table\''); 
    console.log('Tables in database:'); 
    console.log(result);
    
    // Check if users table exists
    const userTable = result.find(table => table.name === 'users');
    if (userTable) {
      console.log('\nUsers table structure:');
      const userColumns = await dbService.query('PRAGMA table_info(users)');
      console.log(userColumns);
    }
    
    // Check if grievances table exists
    const grievancesTable = result.find(table => table.name === 'grievances');
    if (grievancesTable) {
      console.log('\nGrievances table structure:');
      const grievanceColumns = await dbService.query('PRAGMA table_info(grievances)');
      console.log(grievanceColumns);
    }
  } catch (error) { 
    console.error('Error checking tables:', error); 
  } finally { 
    await dbService.close(); 
  } 
} 

checkTables();
