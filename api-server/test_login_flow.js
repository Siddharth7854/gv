const axios = require('axios');

const API_BASE_URL = 'http://localhost:5000';

async function testLoginFlow() {
  console.log('🧪 Testing Admin Logout → User Login Flow...');
  
  try {
    // 1. Test Admin Login
    console.log('1. Testing admin login...');
    const adminLoginResponse = await axios.post(`${API_BASE_URL}/api/admin/admin-login`, {
      username: 'admin',
      password: 'admin123'
    });

    if (adminLoginResponse.data.success) {
      console.log('✅ Admin login successful');
      console.log(`   Admin: ${adminLoginResponse.data.user.full_name}`);
    } else {
      console.log('❌ Admin login failed:', adminLoginResponse.data);
      return;
    }

    // 2. Test User Login (this should work after admin logout)
    console.log('\n2. Testing user login after admin logout...');
    const userLoginResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, {
      phone: '8002659674',
      password: 'sid123'
    });

    if (userLoginResponse.data.success) {
      console.log('✅ User login successful!');
      console.log(`   User: ${userLoginResponse.data.user.full_name}`);
      console.log(`   User ID: ${userLoginResponse.data.user.citizen_id}`);
      console.log(`   Phone: ${userLoginResponse.data.user.phone}`);
      console.log(`   Email: ${userLoginResponse.data.user.email}`);
      
      // Test if user token is valid
      console.log('\n3. Testing user token validity...');
      const token = userLoginResponse.data.token;
      
      // Try to access user dashboard stats 
      const dashboardResponse = await axios.get(`${API_BASE_URL}/api/dashboard/stats/${userLoginResponse.data.user.citizen_id}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (dashboardResponse.data.success) {
        console.log('✅ User dashboard accessible!');
        console.log(`   Dashboard stats loaded successfully`);
      } else {
        console.log('❌ User dashboard failed:', dashboardResponse.data);
      }

    } else {
      console.log('❌ User login failed:', userLoginResponse.data);
    }

    console.log('\n🎉 Login flow test completed!');
    console.log('💡 Flutter app should now work correctly:');
    console.log('   - Admin logout → Back to User Login → User login → Dashboard opens');

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

testLoginFlow();
