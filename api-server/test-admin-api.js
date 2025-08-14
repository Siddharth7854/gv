const http = require('http');

// Function to make an API request
function makeApiRequest(endpoint, token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5000,
      path: `/api/admin/${endpoint}`,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          console.log(`📥 ${endpoint} Status Code:`, res.statusCode);
          if (res.statusCode === 200) {
            const jsonData = JSON.parse(data);
            resolve(jsonData);
          } else {
            console.log(`❌ Error response for ${endpoint}:`, data);
            reject(new Error(`Failed to get ${endpoint}: ${res.statusCode}`));
          }
        } catch (error) {
          reject(error);
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.end();
  });
}

// First, login to get a token
async function testApi() {
  try {
    console.log('🔑 Logging in as admin...');
    // Simulating a direct login request
    const loginOptions = {
      hostname: 'localhost',
      port: 5000,
      path: '/api/admin/admin-login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    };

    const loginPromise = new Promise((resolve, reject) => {
      const req = http.request(loginOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          console.log('📥 Login Status Code:', res.statusCode);
          try {
            if (res.statusCode === 200) {
              const jsonData = JSON.parse(data);
              resolve(jsonData);
            } else {
              console.log('❌ Login error response:', data);
              reject(new Error(`Login failed: ${res.statusCode}`));
            }
          } catch (error) {
            reject(error);
          }
        });
      });

      req.on('error', (error) => {
        reject(error);
      });

      const loginData = JSON.stringify({
        username: 'admin',
        password: 'admin123'
      });
      
      req.write(loginData);
      req.end();
    });

    const loginResult = await loginPromise;
    console.log('✅ Login successful. Token received.');
    const token = loginResult.token;

    // Test different endpoints
    console.log('\n🔍 Testing /api/admin/grievances endpoint...');
    const grievancesResult = await makeApiRequest('grievances?page=1&limit=10', token);
    console.log('✅ Grievances response:', JSON.stringify(grievancesResult, null, 2).substring(0, 500) + '...');
    console.log(`Total grievances: ${grievancesResult.pagination.total}`);

    console.log('\n🔍 Testing /api/admin/users endpoint...');
    const usersResult = await makeApiRequest('users?page=1&limit=10', token);
    console.log('✅ Users response:', JSON.stringify(usersResult, null, 2).substring(0, 500) + '...');
    console.log(`Total users: ${usersResult.pagination.total}`);

    console.log('\n🔍 Testing /api/admin/dashboard-stats endpoint...');
    const statsResult = await makeApiRequest('dashboard-stats', token);
    console.log('✅ Dashboard stats response:', JSON.stringify(statsResult, null, 2));

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

testApi();
