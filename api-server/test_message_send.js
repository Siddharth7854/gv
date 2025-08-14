// Simple test to verify admin message sending after trigger fix
const axios = require('axios');

async function testMessageSending() {
  try {
    console.log('🔍 Testing admin message sending fix...');
    
    // Login first
    const loginResponse = await axios.post('http://localhost:5000/api/admin/login', {
      email: 'admin@example.com',
      password: 'admin123'
    });
    
    const adminToken = loginResponse.data.token;
    console.log('✅ Admin login successful');
    
    // Test sending a message to conversation chat_1
    const messageResponse = await axios.post(
      'http://localhost:5000/api/chat/admin/conversations/chat_1/messages',
      {
        message: 'API test message - triggers fixed!',
        grievance_id: 'GRV202507250001'
      },
      {
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('📤 Message send response:', JSON.stringify(messageResponse.data, null, 2));
    
    if (messageResponse.data.success) {
      console.log('✅ Message sending works! Database integration successful!');
    } else {
      console.log('❌ Message sending failed:', messageResponse.data.error);
    }
    
  } catch (error) {
    console.log('❌ Test failed:', error.response?.data || error.message);
  }
}

testMessageSending();
