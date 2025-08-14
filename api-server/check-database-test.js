const SQLiteService = require('./config/sqlite'); 
const dbService = new SQLiteService(); 

async function checkData() { 
  try { 
    await dbService.connect();
    
    console.log('Checking users table data:');
    const users = await dbService.query('SELECT COUNT(*) as count FROM users');
    console.log(`Total users in database: ${users[0].count}`);
    
    if (users[0].count > 0) {
      const sampleUsers = await dbService.query('SELECT userId, fullName, email FROM users LIMIT 3');
      console.log('Sample users:');
      console.log(sampleUsers);
    }
    
    console.log('\nChecking grievances table data:');
    const grievances = await dbService.query('SELECT COUNT(*) as count FROM grievances');
    console.log(`Total grievances in database: ${grievances[0].count}`);
    
    if (grievances[0].count > 0) {
      const sampleGrievances = await dbService.query('SELECT grievanceId, title, status FROM grievances LIMIT 3');
      console.log('Sample grievances:');
      console.log(sampleGrievances);
    }

    console.log('\nChecking if admin auth is working:');
    // Test admin login query
    const adminLoginQuery = "SELECT adminId, username, email, fullName, password, role FROM admins WHERE username = 'admin' AND isActive = 1";
    console.log(`Running query: ${adminLoginQuery}`);
    const adminResult = await dbService.query(adminLoginQuery);
    console.log(`Admin found: ${adminResult.length > 0 ? 'YES' : 'NO'}`);
    if (adminResult.length > 0) {
      console.log(`Admin username: ${adminResult[0].username}, role: ${adminResult[0].role}`);
    }
  } catch (error) { 
    console.error('Error checking data:', error); 
  } finally { 
    await dbService.close(); 
  } 
} 

checkData();
