const axios = require('axios');

const API_BASE_URL = 'http://localhost:5000';

async function removeAllRestrictions() {
  console.log('🔐 Removing all timeline restrictions from user...');
  
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

    // 2. Remove Login_Restriction control
    console.log('2. Removing Login_Restriction...');
    const removeLoginResponse = await axios.delete(`${API_BASE_URL}/api/admin/timeline-control`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      data: {
        citizen_id: 2,
        control_type: 'Login_Restriction',
        removal_reason: 'Testing completed - login access restored'
      }
    });

    if (removeLoginResponse.data.success) {
      console.log('✅ Login_Restriction removed successfully!');
    } else {
      console.log('❌ Failed to remove Login_Restriction:', removeLoginResponse.data);
    }

    // 3. Remove Activity_Monitor control (optional, doesn't block login)
    console.log('3. Removing Activity_Monitor...');
    const removeMonitorResponse = await axios.delete(`${API_BASE_URL}/api/admin/timeline-control`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      data: {
        citizen_id: 2,
        control_type: 'Activity_Monitor',
        removal_reason: 'Testing completed - monitoring removed'
      }
    });

    if (removeMonitorResponse.data.success) {
      console.log('✅ Activity_Monitor removed successfully!');
    } else {
      console.log('❌ Failed to remove Activity_Monitor:', removeMonitorResponse.data);
    }

    // 4. Check remaining active controls
    console.log('4. Checking remaining active controls...');
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
    } else {
      console.log('🎉 All timeline controls removed! User should be able to login normally now.');
    }

    // 5. Test user login to verify
    console.log('5. Testing user login...');
    const userLoginResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, {
      phone: '8002659674',
      password: 'sid123'
    });

    if (userLoginResponse.data.success) {
      console.log('🎉 User login test SUCCESSFUL!');
      console.log('User:', userLoginResponse.data.user.full_name);
    } else {
      console.log('❌ User login test failed:', userLoginResponse.data);
    }

  } catch (error) {
    if (error.response?.status === 401) {
      console.log('❌ 401 Error - Invalid credentials or token');
    } else if (error.response?.status === 403) {
      console.log('❌ 403 Error - Access restricted:', error.response.data);
    } else {
      console.error('❌ Error:', error.response?.data || error.message);
    }
  }
}

removeAllRestrictions();
