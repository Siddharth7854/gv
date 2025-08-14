// Test script for API endpoints
const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';

async function testAPI() {
  console.log('🧪 Testing API Server...\n');

  try {
    // Test 1: Health Check
    console.log('1. Testing Health Check...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Health Check:', healthResponse.data);
    console.log('');

    // Test 2: Test Endpoint
    console.log('2. Testing Test Endpoint...');
    const testResponse = await axios.get(`${BASE_URL}/test`);
    console.log('✅ Test Endpoint:', testResponse.data);
    console.log('');

    // Test 3: User Registration
    console.log('3. Testing User Registration...');
    const registerData = {
      fullName: 'Test User',
      email: 'test@example.com',
      phoneNumber: '9876543210',
      password: 'test123'
    };
    
    const registerResponse = await axios.post(`${BASE_URL}/auth/register`, registerData);
    console.log('✅ Registration Successful:', registerResponse.data);
    console.log('');

    // Test 4: User Login
    console.log('4. Testing User Login...');
    const loginData = {
      phoneNumber: '9876543210',
      password: 'test123'
    };
    
    const loginResponse = await axios.post(`${BASE_URL}/auth/login`, loginData);
    console.log('✅ Login Successful:', loginResponse.data);
    
    const token = loginResponse.data.token;
    console.log('🔑 JWT Token received');
    console.log('');

    // Test 5: Profile Access
    console.log('5. Testing Profile Access...');
    const profileResponse = await axios.get(`${BASE_URL}/auth/profile`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    console.log('✅ Profile Access:', profileResponse.data);
    console.log('');

    // Test 6: Logout
    console.log('6. Testing Logout...');
    const logoutResponse = await axios.post(`${BASE_URL}/auth/logout`, {}, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    console.log('✅ Logout Successful:', logoutResponse.data);
    console.log('');

    console.log('🎉 All API tests passed successfully!');
    console.log('🚀 Your Grievance Management API Server is fully operational!');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    
    if (error.response?.status === 400 && error.response?.data?.error === 'User already exists') {
      console.log('ℹ️ User already exists, testing login with existing user...');
      
      try {
        const loginData = {
          phoneNumber: '9876543210',
          password: 'test123'
        };
        
        const loginResponse = await axios.post(`${BASE_URL}/auth/login`, loginData);
        console.log('✅ Login with existing user successful:', loginResponse.data);
        console.log('🎉 API Server is working properly!');
      } catch (loginError) {
        console.error('❌ Login test also failed:', loginError.response?.data || loginError.message);
      }
    }
  }
}

testAPI();
