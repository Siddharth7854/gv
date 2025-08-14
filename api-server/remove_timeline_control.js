const axios = require('axios');

const API_BASE_URL = 'http://localhost:5000';

async function removeTimelineControl() {
  console.log('🔐 Removing Account_Suspension from user...');
  
  try {
    // 1. Admin Login
    console.log('1. Admin Login...');
    const loginResponse = await axios.post(`${API_BASE_URL}/api/admin/admin-login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    if (!loginResponse.data.success) {
      throw new Error('Admin login failed');
    }
    
    const token = loginResponse.data.token;
    console.log('✅ Admin logged in successfully');

    // 2. Remove Account_Suspension control
    console.log('2. Removing Account_Suspension...');
    const removeResponse = await axios.delete(`${API_BASE_URL}/api/admin/timeline-control`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      data: {
        citizen_id: 2,
        control_type: 'Account_Suspension',
        removal_reason: 'Testing completed - user access restored'
      }
    });

    if (removeResponse.data.success) {
      console.log('✅ Account_Suspension removed successfully!');
      console.log('Response:', removeResponse.data);
      console.log('🎉 User can now login again');
    } else {
      console.log('❌ Failed to remove control:', removeResponse.data);
    }

    // 3. Check remaining active controls
    console.log('3. Checking remaining active controls...');
    const controlsResponse = await axios.get(`${API_BASE_URL}/api/admin/active-controls/2`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    console.log('✅ Remaining active controls:', controlsResponse.data.data?.length || 0);
    if (controlsResponse.data.data?.length > 0) {
      controlsResponse.data.data.forEach(control => {
        console.log(`   - ${control.control_type}: ${control.reason}`);
      });
    }

  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

removeTimelineControl();
