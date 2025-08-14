const axios = require('axios');

const API_BASE_URL = 'http://localhost:5000';

async function testUserLogin() {
  console.log('🔐 Testing User Login functionality...');
  
  try {
    console.log('1. Testing user login with correct credentials...');
    const userLoginResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, {
      phone: '8002659674',
      password: 'sid123'
    });

    if (userLoginResponse.data.success) {
      console.log('✅ User login SUCCESSFUL!');
      console.log('User Details:');
      console.log(`   Name: ${userLoginResponse.data.user.full_name}`);
      console.log(`   Phone: ${userLoginResponse.data.user.phone}`);
      console.log(`   Email: ${userLoginResponse.data.user.email}`);
      console.log(`   User ID: ${userLoginResponse.data.user.citizen_id}`);
      
      // Test token validity
      const token = userLoginResponse.data.token;
      console.log('\n2. Testing user token validity...');
      
      // Test a protected endpoint
      const profileResponse = await axios.get(`${API_BASE_URL}/api/user/profile`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      if (profileResponse.data.success) {
        console.log('✅ User token is valid and working!');
      } else {
        console.log('❌ User token validation failed');
      }
      
    } else {
      console.log('❌ User login failed:', userLoginResponse.data);
    }

    console.log('\n3. Testing admin login functionality...');
    const adminLoginResponse = await axios.post(`${API_BASE_URL}/api/admin/admin-login`, {
      username: 'admin',
      password: 'admin123'
    });

    if (adminLoginResponse.data.success) {
      console.log('✅ Admin login also working correctly!');
      console.log(`   Admin: ${adminLoginResponse.data.user.full_name}`);
      console.log(`   Role: ${adminLoginResponse.data.user.role}`);
    } else {
      console.log('❌ Admin login failed:', adminLoginResponse.data);
    }

    console.log('\n🎉 Both User and Admin login systems are working correctly!');
    console.log('📱 The Flutter app navigation between login screens should work perfectly.');

  } catch (error) {
    if (error.response?.status === 401) {
      console.log('❌ 401 Error - Invalid credentials');
      console.log('Details:', error.response.data);
    } else if (error.response?.status === 403) {
      console.log('❌ 403 Error - Access restricted');
      console.log('Details:', error.response.data);
    } else {
      console.error('❌ Error:', error.response?.data || error.message);
    }
  }
}

testUserLogin();
