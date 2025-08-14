const axios = require('axios');

async function testAdminLogin() {
  try {
    console.log('🔐 Testing Admin Login...');
    
    const response = await axios.post('http://localhost:5000/api/admin/admin-login', {
      username: 'admin',
      password: 'admin123'
    });
    
    console.log('✅ Admin Login Successful!');
    console.log('Response:', JSON.stringify(response.data, null, 2));
    
    if (response.data.token) {
      console.log('🎟️ JWT Token received:', response.data.token.substring(0, 50) + '...');
    }
    
    if (response.data.user) {
      console.log('👤 Admin User Details:');
      console.log('   Username:', response.data.user.username);
      console.log('   Email:', response.data.user.email);
      console.log('   Full Name:', response.data.user.fullName);
      console.log('   Role:', response.data.user.role);
    }
    
  } catch (error) {
    console.error('❌ Admin Login Failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Error:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }
  }
}

testAdminLogin();
