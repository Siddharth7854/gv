const axios = require('axios');

const API_BASE_URL = 'http://localhost:5000';

async function testDashboardFlow() {
  console.log('🔄 Testing complete dashboard flow...');
  
  try {
    // 1. Test user login
    console.log('1. Testing user login...');
    const loginResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, {
      phone: '8002659674',
      password: 'sid123'
    });

    if (loginResponse.data.success) {
      console.log('✅ User login successful!');
      const token = loginResponse.data.token;
      const userId = loginResponse.data.user.citizen_id;
      
      // 2. Test dashboard stats API
      console.log('2. Testing dashboard stats...');
      const dashboardResponse = await axios.get(`${API_BASE_URL}/api/dashboard/stats/${userId}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (dashboardResponse.data.success) {
        console.log('✅ Dashboard stats loaded successfully!');
        console.log('Stats:', JSON.stringify(dashboardResponse.data.stats, null, 2));
      } else {
        console.log('❌ Dashboard stats failed:', dashboardResponse.data);
      }

      // 3. Test user profile
      console.log('3. Testing user profile...');
      const profileResponse = await axios.get(`${API_BASE_URL}/api/user/profile`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (profileResponse.data.success) {
        console.log('✅ User profile loaded successfully!');
        console.log(`Profile: ${profileResponse.data.user.full_name}`);
      } else {
        console.log('❌ User profile failed:', profileResponse.data);
      }

    } else {
      console.log('❌ User login failed:', loginResponse.data);
    }

    console.log('\n🎉 Dashboard flow test completed!');

  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

testDashboardFlow();
