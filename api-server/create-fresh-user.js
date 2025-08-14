const axios = require('axios');

async function createFreshTestUser() {
  try {
    console.log('🔍 Creating Fresh Test User for Flutter Login...\n');
    
    // Create completely new user with unique phone
    const uniquePhone = '9999' + Date.now().toString().slice(-6); // Generate unique 10-digit phone
    const userData = {
      fullName: 'Flutter Login Test',
      email: `flutter.${Date.now()}@test.gov.in`,
      password: 'test123',
      phoneNumber: uniquePhone,
      department: 'Test Department',
      designation: 'Test User'
    };
    
    console.log('1. Creating fresh test user...');
    console.log(`   Phone: ${uniquePhone}`);
    console.log(`   Password: test123`);
    
    const register = await axios.post('http://localhost:5000/api/auth/register', userData);
    console.log('✅ User created successfully:', register.data.user);
    
    console.log('\n2. Testing login immediately...');
    const login = await axios.post('http://localhost:5000/api/auth/login', {
      phoneNumber: uniquePhone,
      password: 'test123'
    });
    
    console.log('✅ Login successful!');
    console.log('\n📱 USE THESE CREDENTIALS IN FLUTTER:');
    console.log(`   Phone: ${uniquePhone}`);
    console.log(`   Password: test123`);
    console.log('\n🔐 Login Response:', {
      success: login.data.success,
      user: login.data.user.fullName,
      token: login.data.token.substring(0, 20) + '...'
    });
    
  } catch (error) {
    console.log('❌ Error:', error.response?.data || error.message);
  }
}

createFreshTestUser();
