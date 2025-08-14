const sql = require('mssql');

// Alternative connection configurations to try
const connectionConfigs = [
  {
    name: 'Named Pipes (Windows)',
    config: {
      server: '\\\\.\\pipe\\MSSQL$SQLEXPRESS\\sql\\query',
      database: 'master',
      options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
        useUTC: false,
        connectTimeout: 60000,
        requestTimeout: 60000,
      }
    }
  },
  {
    name: 'Localhost with Instance',
    config: {
      server: 'localhost\\SQLEXPRESS',
      database: 'master',
      options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
        instanceName: 'SQLEXPRESS',
        useUTC: false,
        connectTimeout: 60000,
        requestTimeout: 60000,
      }
    }
  },
  {
    name: 'Dynamic Port Discovery',
    config: {
      server: 'DESKTOP-E2H6BA3\\SQLEXPRESS',
      database: 'master',
      options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
        instanceName: 'SQLEXPRESS',
        useUTC: false,
        connectTimeout: 60000,
        requestTimeout: 60000,
        // Let SQL Server Browser find the port
        port: undefined
      }
    }
  },
  {
    name: 'Force TCP with specific port',
    config: {
      server: 'DESKTOP-E2H6BA3,49159', // Common SQL Express dynamic port
      database: 'master',
      options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
        useUTC: false,
        connectTimeout: 60000,
        requestTimeout: 60000,
      }
    }
  }
];

async function testAlternativeConnections() {
  console.log('🔍 Testing alternative SQL Server connection methods...\n');
  
  for (const { name, config } of connectionConfigs) {
    console.log(`📡 Testing: ${name}`);
    console.log(`   Server: ${config.server}`);
    
    try {
      const pool = await sql.connect(config);
      console.log(`✅ SUCCESS: ${name} connected!`);
      
      // Test basic query
      const result = await pool.request().query('SELECT @@SERVERNAME as server, @@VERSION as version');
      console.log(`   Server: ${result.recordset[0].server}`);
      console.log(`   Version: ${result.recordset[0].version.substring(0, 50)}...`);
      
      await pool.close();
      console.log(`🎯 WORKING CONFIG FOUND!`);
      
      // Show the working configuration
      console.log('\n' + '='.repeat(60));
      console.log('WORKING CONFIGURATION:');
      console.log('='.repeat(60));
      console.log(JSON.stringify(config, null, 2));
      console.log('='.repeat(60));
      
      return config;
      
    } catch (error) {
      console.log(`❌ FAILED: ${name}`);
      console.log(`   Error: ${error.message}\n`);
    }
  }
  
  console.log('💥 All connection methods failed!');
  console.log('\n🔧 SQL Server Configuration Required:');
  console.log('1. Open SQL Server Configuration Manager');
  console.log('2. Go to SQL Server Network Configuration > Protocols for SQLEXPRESS');
  console.log('3. Enable "Named Pipes" and "TCP/IP"');
  console.log('4. Restart SQL Server Express service');
  console.log('5. Start SQL Server Browser service');
  
  return null;
}

async function enableSQLServerProtocols() {
  console.log('\n🔧 Attempting to enable SQL Server protocols via registry...');
  
  const { exec } = require('child_process');
  const util = require('util');
  const execAsync = util.promisify(exec);
  
  try {
    // Enable TCP/IP protocol
    console.log('📝 Enabling TCP/IP protocol...');
    await execAsync(`reg add "HKLM\\SOFTWARE\\Microsoft\\Microsoft SQL Server\\MSSQL15.SQLEXPRESS\\MSSQLServer\\SuperSocketNetLib\\Tcp" /v Enabled /t REG_DWORD /d 1 /f`);
    
    // Enable Named Pipes
    console.log('📝 Enabling Named Pipes...');
    await execAsync(`reg add "HKLM\\SOFTWARE\\Microsoft\\Microsoft SQL Server\\MSSQL15.SQLEXPRESS\\MSSQLServer\\SuperSocketNetLib\\Np" /v Enabled /t REG_DWORD /d 1 /f`);
    
    // Set TCP port
    console.log('📝 Setting TCP port...');
    await execAsync(`reg add "HKLM\\SOFTWARE\\Microsoft\\Microsoft SQL Server\\MSSQL15.SQLEXPRESS\\MSSQLServer\\SuperSocketNetLib\\Tcp\\IPAll" /v TcpPort /t REG_SZ /d 1433 /f`);
    
    console.log('✅ Registry updated successfully');
    console.log('⚠️ You need to restart SQL Server Express service for changes to take effect');
    
  } catch (error) {
    console.log('❌ Registry update failed:', error.message);
    console.log('💡 You may need to run as Administrator');
  }
}

async function main() {
  const workingConfig = await testAlternativeConnections();
  
  if (!workingConfig) {
    await enableSQLServerProtocols();
  }
}

main().catch(console.error);
