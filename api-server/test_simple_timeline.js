const axios = require('axios');

const API_BASE = 'http://localhost:5000/api';
const ADMIN_CREDENTIALS = {
  username: 'admin',
  password: 'admin123'
};

async function testBasicFlow() {
  try {
    console.log('🔐 Testing Basic Timeline Control...\n');

    // Step 1: Admin Login
    console.log('1. Admin Login...');
    const adminLoginResponse = await axios.post(`${API_BASE}/admin/admin-login`, ADMIN_CREDENTIALS);
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in successfully\n');

    // Step 2: Test database connection by getting user timeline first
    console.log('2. Getting user timeline (should work even if no activities)...');
    try {
      const timelineResponse = await axios.get(`${API_BASE}/admin/user-timeline/2`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      console.log('✅ Timeline API working, activities:', timelineResponse.data.data?.length || 0);
    } catch (error) {
      console.log('❌ Timeline API error:', error.response?.data?.error || error.message);
      return;
    }

    // Step 3: Test simple SP call first - let's try to log an activity manually
    console.log('\n3. Testing manual activity logging...');
    try {
      // First, let's create a simple test endpoint to validate our stored procedures
      console.log('Applying a simple timeline control...');
      
      const controlData = {
        citizen_id: 2,
        control_type: 'Account_Suspension',
        reason: 'Testing timeline control system',
        end_date: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24 hours from now
        notes: 'This is a test suspension for system validation'
      };

      const response = await axios.post(`${API_BASE}/admin/timeline-control`, controlData, {
        headers: { 
          Authorization: `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (response.data.success) {
        console.log('✅ Timeline control applied successfully!');
        console.log('Response:', response.data);
      } else {
        console.log('❌ Timeline control failed:', response.data);
      }
    } catch (error) {
      console.log('❌ Timeline control error:');
      console.log('Status:', error.response?.status);
      console.log('Error:', error.response?.data?.error || error.message);
      console.log('Full response data:', JSON.stringify(error.response?.data, null, 2));
      
      // Let's also check what the server is returning
      if (error.response?.data) {
        console.log('\n🔍 Detailed error analysis:');
        console.log('- Error type:', typeof error.response.data.error);
        console.log('- Error message:', error.response.data.error);
        console.log('- Success field:', error.response.data.success);
      }
    }

  } catch (error) {
    console.error('❌ Test failed completely:', error.message);
    if (error.response?.data) {
      console.error('Response data:', JSON.stringify(error.response.data, null, 2));
    }
  }
}

testBasicFlow();
