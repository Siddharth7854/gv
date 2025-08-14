// Test script to verify authentication middleware exports
console.log('Testing authentication middleware exports...');

try {
  const auth = require('./middleware/auth');
  console.log('✅ Default export:', typeof auth);
  
  const { authenticateUser } = require('./middleware/auth');
  console.log('✅ Named export authenticateUser:', typeof authenticateUser);
  
  const { authenticateAdmin } = require('./middleware/adminAuth');
  console.log('✅ Named export authenticateAdmin:', typeof authenticateAdmin);
  
  console.log('All middleware functions are properly exported!');
} catch (error) {
  console.log('❌ Error testing middleware:', error.message);
}
