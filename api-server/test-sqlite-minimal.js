console.log('Starting minimal SQLite test...');

const SQLiteService = require('./config/sqlite');

async function test() {
  try {
    console.log('Creating SQLite service...');
    const dbService = new SQLiteService();
    
    console.log('Connecting to SQLite...');
    await dbService.connect();
    
    console.log('✅ SQLite connected successfully!');
    console.log('Database path:', dbService.dbPath);
    
    await dbService.close();
    console.log('✅ Test completed successfully!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

test();
