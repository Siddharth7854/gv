// test_grievance_update.js - Test for updating grievances with image URLs
const axios = require('axios');

// Configuration
const API_BASE_URL = 'http://localhost:5000/api/admin';
const ADMIN_USERNAME = 'admin';
const ADMIN_PASSWORD = 'admin123';
const TEST_GRIEVANCE_ID = process.argv[2] || 'GRV_1755128211741_a94505dd'; // Pass ID as command line argument or use default

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

// Helper to log with colors
const log = {
  info: (msg) => console.log(`${colors.blue}[INFO]${colors.reset} ${msg}`),
  success: (msg) => console.log(`${colors.green}[SUCCESS]${colors.reset} ${msg}`),
  error: (msg) => console.log(`${colors.red}[ERROR]${colors.reset} ${msg}`),
  warning: (msg) => console.log(`${colors.yellow}[WARNING]${colors.reset} ${msg}`),
  step: (msg) => console.log(`${colors.cyan}[STEP]${colors.reset} ${msg}`),
  json: (label, obj) => console.log(`${colors.magenta}[${label}]${colors.reset}`, JSON.stringify(obj, null, 2)),
};

// Main test function
async function runTest() {
  try {
    log.step('STARTING GRIEVANCE UPDATE TEST');
    log.info(`Testing update for grievance ID: ${TEST_GRIEVANCE_ID}`);
    
    // Step 1: Log in as admin
    log.step('1. Logging in as admin');
    const loginResponse = await axios.post(`${API_BASE_URL}/admin-login`, {
      username: ADMIN_USERNAME,
      password: ADMIN_PASSWORD
    });
    
    if (!loginResponse.data.token) {
      log.error('Login failed - no token received');
      process.exit(1);
    }
    
    log.success('Admin login successful');
    const token = loginResponse.data.token;
    log.json('Token', { token: `${token.substring(0, 15)}...` });
    
    // Step 2: Get current grievance details
    log.step('2. Getting current grievance details');
    try {
      const grievanceResponse = await axios.get(`${API_BASE_URL}/grievances`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      const grievances = grievanceResponse.data.data?.grievances || [];
      const targetGrievance = grievances.find(g => g.grievanceId === TEST_GRIEVANCE_ID || g.id === TEST_GRIEVANCE_ID);
      
      if (!targetGrievance) {
        log.warning(`Grievance ${TEST_GRIEVANCE_ID} not found, will try update anyway`);
      } else {
        log.json('Current Grievance', {
          id: targetGrievance.grievanceId || targetGrievance.id,
          title: targetGrievance.title,
          status: targetGrievance.status
        });
      }
    } catch (error) {
      log.warning('Could not get current grievance details, continuing with update test');
    }
    
    // Step 3: Update the grievance with new status and test images
    log.step('3. Updating grievance with new status and image URLs');
    
    // Generate test image URLs
    const testImageUrls = [
      `test_image_${Date.now()}_1.jpg`,
      `test_image_${Date.now()}_2.jpg`
    ];
    
    const updateData = {
      status: 'In Progress', // Test status
      comments: 'Test update from API verification script',
      progress_photos: testImageUrls
    };
    
    log.json('Update Data', updateData);
    
    try {
      // First try with new endpoint
      log.info('Trying with new endpoint: update-with-images');
      const updateResponse = await axios.put(
        `${API_BASE_URL}/grievances/${TEST_GRIEVANCE_ID}/update-with-images`,
        updateData,
        { headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }}
      );
      
      log.json('Update Response', updateResponse.data);
      log.success('Grievance update successful with new endpoint!');
    } catch (error) {
      log.error(`Failed to update with new endpoint: ${error.message}`);
      
      // Fallback to old endpoint
      try {
        log.info('Trying with fallback endpoint: status');
        const fallbackResponse = await axios.put(
          `${API_BASE_URL}/grievances/${TEST_GRIEVANCE_ID}/status`,
          updateData,
          { headers: { 
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }}
        );
        
        log.json('Fallback Response', fallbackResponse.data);
        log.success('Grievance update successful with fallback endpoint!');
      } catch (fallbackError) {
        log.error(`Fallback update also failed: ${fallbackError.message}`);
        if (fallbackError.response) {
          log.json('Error Response', fallbackError.response.data);
        }
        process.exit(1);
      }
    }
    
    // Step 4: Verify the update
    log.step('4. Verifying the update');
    try {
      const verifyResponse = await axios.get(`${API_BASE_URL}/grievances`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      const grievances = verifyResponse.data.data?.grievances || [];
      const updatedGrievance = grievances.find(g => g.grievanceId === TEST_GRIEVANCE_ID || g.id === TEST_GRIEVANCE_ID);
      
      if (!updatedGrievance) {
        log.warning(`Could not verify update - grievance ${TEST_GRIEVANCE_ID} not found`);
      } else {
        log.json('Updated Grievance', {
          id: updatedGrievance.grievanceId || updatedGrievance.id,
          title: updatedGrievance.title,
          status: updatedGrievance.status,
          comments: updatedGrievance.adminComments
        });
        
        if (updatedGrievance.status === updateData.status) {
          log.success('✓ Status successfully updated!');
        } else {
          log.error(`✗ Status not updated. Expected: ${updateData.status}, Got: ${updatedGrievance.status}`);
        }
      }
    } catch (error) {
      log.error(`Verification failed: ${error.message}`);
    }
    
    log.success('TEST COMPLETED');
  } catch (error) {
    log.error(`Test failed: ${error.message}`);
    if (error.response) {
      log.json('Error Response', error.response.data);
    }
    process.exit(1);
  }
}

// Run the test
runTest();
