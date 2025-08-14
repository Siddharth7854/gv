const axios = require('axios');

const baseUrl = 'http://localhost:5000/api';

// Test admin login and then test chat endpoints
async function testChatAPI() {
  try {
    console.log('🔐 Testing admin login...');
    
    // Admin login
    const loginResponse = await axios.post(`${baseUrl}/admin/admin-login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    if (!loginResponse.data.success) {
      throw new Error('Admin login failed');
    }
    
    const adminToken = loginResponse.data.token;
    console.log('✅ Admin login successful');
    
    const headers = {
      'Authorization': `Bearer ${adminToken}`,
      'Content-Type': 'application/json'
    };
    
    // Test 1: Get chat conversations
    console.log('\n📥 Testing: Get chat conversations...');
    const conversationsResponse = await axios.get(`${baseUrl}/chat/admin/conversations`, { headers });
    
    console.log(`✅ Found ${conversationsResponse.data.conversations.length} conversations`);
    console.log('Conversations:', JSON.stringify(conversationsResponse.data.conversations, null, 2));
    
    if (conversationsResponse.data.conversations.length > 0) {
      const conversationId = conversationsResponse.data.conversations[0].id;
      
      // Test 2: Get messages for conversation
      console.log(`\n💬 Testing: Get messages for conversation ${conversationId}...`);
      const messagesResponse = await axios.get(`${baseUrl}/chat/admin/conversations/${conversationId}/messages`, { headers });
      
      console.log(`✅ Found ${messagesResponse.data.messages.length} messages`);
      console.log('Messages:', JSON.stringify(messagesResponse.data.messages, null, 2));
      
      // Test 3: Send admin message
      console.log(`\n📤 Testing: Send admin message...`);
      const sendResponse = await axios.post(`${baseUrl}/chat/admin/conversations/${conversationId}/messages`, {
        message: 'Hello! This is a test message from admin API.',
        grievance_id: 'GRV202508050008'
      }, { headers });
      
      console.log('✅ Message sent successfully');
      console.log('Response:', JSON.stringify(sendResponse.data, null, 2));
      
      // Test 4: Mark as read
      console.log(`\n📖 Testing: Mark conversation as read...`);
      const readResponse = await axios.patch(`${baseUrl}/chat/admin/conversations/${conversationId}/read`, {}, { headers });
      
      console.log('✅ Conversation marked as read');
      console.log('Response:', JSON.stringify(readResponse.data, null, 2));
      
      // Test 5: Get conversations again to see updated data
      console.log('\n🔄 Testing: Get conversations again to verify changes...');
      const updatedConversationsResponse = await axios.get(`${baseUrl}/chat/admin/conversations`, { headers });
      
      console.log(`✅ Updated conversations retrieved`);
      console.log('Updated conversations:', JSON.stringify(updatedConversationsResponse.data.conversations, null, 2));
    }
    
    console.log('\n🎉 All chat API tests completed successfully!');
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testChatAPI();
