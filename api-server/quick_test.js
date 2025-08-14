const axios = require('axios');

async function quickTest() {
  try {
    console.log('🔐 Quick Admin Login Test...');
    
    const response = await axios.post('http://localhost:5000/api/admin/admin-login', {
      username: 'admin',
      password: 'admin123'
    }, {
      timeout: 5000
    });
    
    console.log('✅ Success!');
    console.log('Status:', response.status);
    console.log('Data:', JSON.stringify(response.data, null, 2));
    
  } catch (error) {
    console.error('❌ Error:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else if (error.request) {
      console.error('Request failed - no response received');
    } else {
      console.error('Error:', error.message);
    }
  }
}

quickTest();
