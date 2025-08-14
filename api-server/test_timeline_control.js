const axios = require('axios');

// Configuration
const API_BASE = 'http://localhost:5000/api';
const ADMIN_CREDENTIALS = {
  username: 'admin',
  password: 'admin123'
};

let adminToken = '';
let testCitizenId = 2; // Using existing test user

async function main() {
  try {
    console.log('🔐 Testing Admin Timeline Control System...\n');

    // Step 1: Admin Login
    console.log('1. Admin Login...');
    const adminLoginResponse = await axios.post(`${API_BASE}/admin/admin-login`, ADMIN_CREDENTIALS);
    adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in successfully\n');

    // Step 2: Get User Timeline (before any controls)
    console.log('2. Getting user timeline...');
    const timelineResponse = await axios.get(`${API_BASE}/admin/user-timeline/${testCitizenId}`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    console.log('✅ User timeline fetched:', timelineResponse.data.data.length, 'activities\n');

    // Step 3: Get User Activity Summary
    console.log('3. Getting user activity summary...');
    const activitySummaryResponse = await axios.get(`${API_BASE}/admin/user-activity-summary/${testCitizenId}`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    console.log('✅ Activity summary:', activitySummaryResponse.data.data);
    console.log('   Total activities:', activitySummaryResponse.data.data.totalActivities);
    console.log('   Active sessions:', activitySummaryResponse.data.data.sessions.length);
    console.log('');

    // Step 4: Apply Timeline Control (Account Suspension)
    console.log('4. Applying account suspension...');
    const suspensionResponse = await axios.post(`${API_BASE}/admin/timeline-control`, {
      citizen_id: testCitizenId,
      control_type: 'Account_Suspension',
      reason: 'Testing timeline control system',
      end_date: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24 hours from now
      notes: 'This is a test suspension for system validation'
    }, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    console.log('✅ Account suspension applied successfully\n');

    // Step 5: Get Active Timeline Controls
    console.log('5. Getting active timeline controls...');
    const controlsResponse = await axios.get(`${API_BASE}/admin/active-controls/${testCitizenId}`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    console.log('✅ Active controls:', controlsResponse.data.data.length);
    controlsResponse.data.data.forEach(control => {
      console.log(`   - ${control.control_type}: ${control.reason}`);
      console.log(`     Applied by: ${control.admin_name} on ${control.created_at}`);
    });
    console.log('');

    // Step 6: Apply Login Restriction
    console.log('6. Applying login restriction...');
    const loginRestrictionResponse = await axios.post(`${API_BASE}/admin/timeline-control`, {
      citizen_id: testCitizenId,
      control_type: 'Login_Restriction',
      reason: 'Multiple failed login attempts detected',
      end_date: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(), // 2 hours from now
      notes: 'Temporary restriction due to security concerns'
    }, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    console.log('✅ Login restriction applied successfully\n');

    // Step 7: Force User Logout
    console.log('7. Forcing user logout...');
    const forceLogoutResponse = await axios.post(`${API_BASE}/admin/force-logout`, {
      citizen_id: testCitizenId,
      reason: 'Security policy enforcement'
    }, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    console.log('✅ User logout forced successfully\n');

    // Step 8: Get Updated Activity Summary
    console.log('8. Getting updated activity summary...');
    const updatedSummaryResponse = await axios.get(`${API_BASE}/admin/user-activity-summary/${testCitizenId}`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    console.log('✅ Updated activity summary:');
    console.log('   Total activities:', updatedSummaryResponse.data.data.totalActivities);
    console.log('   Recent activities:');
    updatedSummaryResponse.data.data.activities.forEach(activity => {
      console.log(`   - ${activity.activity_type}: ${activity.count} times (last: ${activity.last_activity})`);
    });
    console.log('');

    // Step 9: Test Bulk Timeline Control
    console.log('9. Testing bulk timeline control...');
    const bulkResponse = await axios.post(`${API_BASE}/admin/bulk-timeline-control`, {
      citizen_ids: [testCitizenId],
      control_type: 'Activity_Monitor',
      reason: 'Enhanced monitoring for security analysis',
      end_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days from now
      notes: 'Monitoring user activity for security assessment'
    }, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    console.log('✅ Bulk timeline control applied:', bulkResponse.data.results);
    console.log('');

    // Step 10: Get All Active Controls
    console.log('10. Getting all active timeline controls...');
    const allControlsResponse = await axios.get(`${API_BASE}/admin/active-controls`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    console.log('✅ All active controls in system:', allControlsResponse.data.data.length);
    allControlsResponse.data.data.forEach(control => {
      console.log(`   - User: ${control.full_name} (${control.phone})`);
      console.log(`     Control: ${control.control_type} - ${control.reason}`);
      console.log(`     Applied by: ${control.admin_name} on ${control.created_at}`);
      console.log('');
    });

    // Step 11: Remove Timeline Control
    console.log('11. Removing account suspension...');
    const removeControlResponse = await axios.delete(`${API_BASE}/admin/timeline-control`, {
      data: {
        citizen_id: testCitizenId,
        control_type: 'Account_Suspension',
        removal_reason: 'Test completed successfully'
      },
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    console.log('✅ Account suspension removed successfully\n');

    // Step 12: Final Timeline Check
    console.log('12. Final timeline check...');
    const finalTimelineResponse = await axios.get(`${API_BASE}/admin/user-timeline/${testCitizenId}?pageSize=10`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    console.log('✅ Final timeline (last 10 activities):');
    finalTimelineResponse.data.data.forEach((activity, index) => {
      console.log(`   ${index + 1}. ${activity.activity_type}: ${activity.activity_description || 'N/A'}`);
      console.log(`      Time: ${activity.created_at}, Status: ${activity.status}`);
    });

    console.log('\n🎉 Timeline Control System Test Completed Successfully!');
    console.log('\n📊 Test Summary:');
    console.log('   ✅ User timeline retrieval');
    console.log('   ✅ Activity summary generation');
    console.log('   ✅ Timeline control application');
    console.log('   ✅ Multiple control types support');
    console.log('   ✅ Force user logout');
    console.log('   ✅ Bulk operations');
    console.log('   ✅ Control removal');
    console.log('   ✅ Comprehensive activity logging');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    if (error.response?.data) {
      console.error('Response data:', JSON.stringify(error.response.data, null, 2));
    }
  }
}

main();
