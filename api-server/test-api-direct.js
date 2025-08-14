const axios = require('axios');

async function testDirectAPICall() {
  try {
    console.log('🔍 Testing Direct API Call to Server...\n');
    
    // Test the exact same call that Flutter is making
    console.log('🌐 API Base URL: http://localhost:5000/api');
    console.log('🔗 Login Endpoint: http://localhost:5000/api/auth/login');
    
    console.log('\n1. Testing Health Check...');
    const health = await axios.get('http://localhost:5000/api/health');
    console.log('✅ Health Check:', health.data.status);
    
    console.log('\n2. Testing Login API with fresh user...');
    const loginData = {
      phoneNumber: '9999987407',
      password: 'test123'
    };
    
    console.log('📱 Request Data:', loginData);
    
    const response = await axios.post('http://localhost:5000/api/auth/login', loginData, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    });
    
    console.log('✅ Login API Response:');
    console.log('   Status:', response.status);
    console.log('   Success:', response.data.success);
    console.log('   User:', response.data.user?.fullName);
    console.log('   Token Preview:', response.data.token?.substring(0, 20) + '...');
    
    console.log('\n🎉 API is working perfectly!');
    console.log('📱 Problem is in Flutter app - not server!');
    
  } catch (error) {
    console.log('❌ API Error:', {
      status: error.response?.status,
      statusText: error.response?.statusText,
      data: error.response?.data,
      message: error.message
    });
  }
}

testDirectAPICall();
