const sql = require('mssql');

// Multiple connection approaches
const configs = [
  {
    name: 'Named Instance (Full Computer Name)',
    config: {
      server: 'DESKTOP-E2H6BA3\\SQLEXPRESS',
      database: 'master',
      authentication: { type: 'default' },
      options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
        integratedSecurity: true,
        instanceName: 'SQLEXPRESS'
      },
      connectionTimeout: 30000,
      requestTimeout: 30000,
    }
  },
  {
    name: 'Localhost Named Instance',
    config: {
      server: 'localhost\\SQLEXPRESS',
      database: 'master',
      authentication: { type: 'default' },
      options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
        integratedSecurity: true,
      },
      connectionTimeout: 30000,
      requestTimeout: 30000,
    }
  },
  {
    name: 'Local dot notation',
    config: {
      server: '.\\SQLEXPRESS',
      database: 'master', 
      authentication: { type: 'default' },
      options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
        integratedSecurity: true,
      },
      connectionTimeout: 30000,
      requestTimeout: 30000,
    }
  },
  {
    name: 'SQL Authentication (if enabled)',
    config: {
      server: 'DESKTOP-E2H6BA3\\SQLEXPRESS',
      database: 'master',
      user: 'sa',
      password: 'Sid91221',
      options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
      },
      connectionTimeout: 30000,
      requestTimeout: 30000,
    }
  }
];

async function testAllConnectionMethods() {
  console.log('🔍 Testing ALL SQL Server connection methods...\n');
  
  for (const { name, config } of configs) {
    console.log(`📡 Testing: ${name}`);
    console.log(`   Server: ${config.server}`);
    
    try {
      const pool = await sql.connect(config);
      console.log(`✅ SUCCESS: ${name} connection established!`);
      
      // Test a simple query
      const result = await pool.request().query('SELECT @@VERSION as version, @@SERVERNAME as serverName');
      console.log(`   Server Name: ${result.recordset[0].serverName}`);
      console.log(`   Version: ${result.recordset[0].version.substring(0, 60)}...`);
      
      // Check protocols
      const protocolResult = await pool.request().query(`
        SELECT 
          local_net_address,
          local_tcp_port,
          net_transport
        FROM sys.dm_exec_connections 
        WHERE session_id = @@SPID
      `);
      
      if (protocolResult.recordset.length > 0) {
        const conn = protocolResult.recordset[0];
        console.log(`   Connection: ${conn.net_transport} on ${conn.local_net_address}:${conn.local_tcp_port}`);
      }
      
      await pool.close();
      console.log(`🎯 WORKING CONFIG FOUND!\n`);
      
      // Update database.js with working config
      console.log('=' * 60);
      console.log('COPY THIS CONFIG TO database.js:');
      console.log('=' * 60);
      console.log(JSON.stringify(config, null, 2));
      console.log('=' * 60);
      
      return config; // Return working config
      
    } catch (error) {
      console.log(`❌ FAILED: ${name} - ${error.message}`);
      console.log('');
    }
  }
  
  console.log('💥 ALL CONNECTION METHODS FAILED');
  console.log('');
  console.log('🔧 TROUBLESHOOTING STEPS:');
  console.log('1. Open SQL Server Configuration Manager');
  console.log('2. Enable Named Pipes and TCP/IP protocols');
  console.log('3. Restart SQL Server Express service');
  console.log('4. Check Windows Firewall settings');
  console.log('5. Verify SQL Server Express is actually installed');
}

testAllConnectionMethods().catch(console.error);
