const sql = require('mssql');

// Alternative configurations to try
const configs = [
  {
    name: 'SQL Server Express (Windows Auth)',
    config: {
      server: 'DESKTOP-E2H6BA3\\SQLEXPRESS',
      database: 'master',
      authentication: {
        type: 'default'
      },
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
    name: 'SQL Server Express (TCP/IP)',
    config: {
      server: 'DESKTOP-E2H6BA3,1433',
      database: 'master',
      authentication: {
        type: 'default'
      },
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
    name: 'LocalDB',
    config: {
      server: '(localdb)\\MSSQLLocalDB',
      database: 'master',
      authentication: {
        type: 'default'
      },
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
    name: 'LocalDB v11.0',
    config: {
      server: '(localdb)\\v11.0',
      database: 'master',
      authentication: {
        type: 'default'
      },
      options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true,
        integratedSecurity: true,
      },
      connectionTimeout: 30000,
      requestTimeout: 30000,
    }
  }
];

async function testAllConfigurations() {
  console.log('🔍 Testing multiple SQL Server configurations...\n');
  
  for (const { name, config } of configs) {
    console.log(`📡 Testing: ${name}`);
    console.log(`   Server: ${config.server}`);
    
    try {
      const pool = await sql.connect(config);
      console.log(`✅ SUCCESS: ${name} connection established!`);
      
      // Test a simple query
      const result = await pool.request().query('SELECT @@VERSION as version');
      console.log(`   Version: ${result.recordset[0].version.substring(0, 100)}...`);
      
      await pool.close();
      console.log(`🎯 RECOMMENDED: Use this configuration for your app\n`);
      
      // Generate the working config
      console.log('Working Configuration:');
      console.log('='.repeat(50));
      console.log(JSON.stringify(config, null, 2));
      console.log('='.repeat(50));
      break;
      
    } catch (error) {
      console.log(`❌ FAILED: ${name}`);
      console.log(`   Error: ${error.message}`);
      console.log('');
    }
  }
}

testAllConfigurations().catch(console.error);
