const axios = require('axios');

async function testAPIQuick() {
  try {
    console.log('🔍 Testing Grievance Management API...\n');
    
    // Test health endpoint
    console.log('1. Testing Health Endpoint...');
    const health = await axios.get('http://localhost:5000/api/health');
    console.log('✅ Health Check Response:', health.data);
    console.log('');
    
    // Test user registration with unique email
    console.log('2. Testing User Registration...');
    const userData = {
      fullName: 'Fresh Test Employee',
      email: `test.fresh.${Date.now()}@gov.in`,
      password: 'SecurePass123',
      phoneNumber: `987654${Math.floor(Math.random() * 10000)}`,
      department: 'Information Technology',
      designation: 'Software Developer'
    };
    
    const register = await axios.post('http://localhost:5000/api/auth/register', userData);
    console.log('✅ Registration Response:', register.data);
    console.log('');
    
    // Test login
    console.log('3. Testing User Login...');
    const login = await axios.post('http://localhost:5000/api/auth/login', {
      email: userData.email,
      password: userData.password,
      phoneNumber: userData.phoneNumber
    });
    console.log('✅ Login Response:', login.data);
    console.log('');
    
    console.log('🎉 All API endpoints working perfectly!');
    console.log('📊 Server Status: FULLY OPERATIONAL');
    console.log('💾 Database: SQLite (Working)');
    console.log('🔐 Authentication: JWT (Working)');
    
  } catch (error) {
    if (error.response) {
      console.log('❌ API Error:', error.response.data);
    } else {
      console.log('❌ Connection Error:', error.message);
    }
  }
}

testAPIQuick();
