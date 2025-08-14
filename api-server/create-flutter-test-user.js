const axios = require('axios');

async function createTestUser() {
  try {
    console.log('🔍 Creating test user for Flutter login...\n');
    
    // Create a test user first
    const userData = {
      fullName: 'Flutter Test User',
      email: 'flutter.test@gov.in',
      password: 'flutter123',
      phoneNumber: '9876543210',
      department: 'Test Department',
      designation: 'Test User'
    };
    
    console.log('1. Creating test user...');
    try {
      const register = await axios.post('http://localhost:5000/api/auth/register', userData);
      console.log('✅ Test user created:', register.data.user);
    } catch (error) {
      if (error.response?.data?.error === 'User already exists') {
        console.log('✅ Test user already exists');
      } else {
        console.log('❌ Registration failed:', error.response?.data);
        return;
      }
    }
    
    console.log('\n2. Testing login with Flutter credentials...');
    const login = await axios.post('http://localhost:5000/api/auth/login', {
      phoneNumber: '9876543210',
      password: 'flutter123'
    });
    
    console.log('✅ Login successful!');
    console.log('📱 Use these credentials in Flutter:');
    console.log('   Phone: 9876543210');
    console.log('   Password: flutter123');
    console.log('\n🔐 Token:', login.data.token);
    
  } catch (error) {
    console.log('❌ Error:', error.response?.data || error.message);
  }
}

createTestUser();
