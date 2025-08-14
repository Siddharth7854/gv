const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

async function checkSQLServerStatus() {
  console.log('🔍 Checking SQL Server Installation and Services...\n');
  
  try {
    // Check for SQL Server services using WMI
    console.log('📋 Checking SQL Server services...');
    const { stdout: services } = await execAsync(`wmic service where "name like '%SQL%'" get name,state,startmode /format:table`);
    console.log(services);
    
    // Check for SQL Server processes
    console.log('\n🔄 Checking SQL Server processes...');
    const { stdout: processes } = await execAsync(`tasklist /fi "imagename eq sqlservr.exe" /fo table`);
    console.log(processes);
    
    // Check SQL Server registry entries
    console.log('\n📝 Checking SQL Server installation...');
    try {
      const { stdout: regInfo } = await execAsync(`reg query "HKLM\\SOFTWARE\\Microsoft\\Microsoft SQL Server" /v InstalledInstances`);
      console.log(regInfo);
    } catch (regError) {
      console.log('❌ No SQL Server registry entries found');
    }
    
    // Check for SQL Server Express specifically
    console.log('\n🔍 Checking SQL Server Express...');
    try {
      const { stdout: expressInfo } = await execAsync(`sc query MSSQL$SQLEXPRESS`);
      console.log(expressInfo);
    } catch (scError) {
      console.log('❌ SQL Server Express service not found:', scError.message);
    }
    
    // Try to start SQL Server Browser
    console.log('\n🚀 Attempting to start SQL Server Browser...');
    try {
      const { stdout: browserStart } = await execAsync(`sc start SQLBrowser`);
      console.log(browserStart);
    } catch (browserError) {
      console.log('⚠️ Could not start SQL Server Browser:', browserError.message);
    }
    
  } catch (error) {
    console.log('❌ Error checking SQL Server status:', error.message);
  }
}

async function suggestAlternativeDatabase() {
  console.log('\n💡 ALTERNATIVE DATABASE OPTIONS:\n');
  
  console.log('1. 🗄️ SQLite (Recommended for development):');
  console.log('   - No server setup required');
  console.log('   - File-based database');
  console.log('   - npm install sqlite3');
  console.log('');
  
  console.log('2. 🐘 PostgreSQL:');
  console.log('   - Download from postgresql.org');
  console.log('   - More reliable than SQL Server Express');
  console.log('   - npm install pg');
  console.log('');
  
  console.log('3. 🍃 MongoDB:');
  console.log('   - NoSQL database');
  console.log('   - Download from mongodb.com');
  console.log('   - npm install mongodb');
  console.log('');
  
  console.log('4. 🔄 Continue with SQL Server:');
  console.log('   - Download SQL Server Express from Microsoft');
  console.log('   - Enable Mixed Mode Authentication');
  console.log('   - Enable TCP/IP and Named Pipes');
}

async function main() {
  await checkSQLServerStatus();
  await suggestAlternativeDatabase();
  
  console.log('\n🎯 RECOMMENDATION:');
  console.log('For quick development, use SQLite.');
  console.log('For production, properly configure SQL Server Express.');
}

main().catch(console.error);
