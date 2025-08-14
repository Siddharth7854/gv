// apply_grievance_update_fix.js - Apply the fix for grievance updates
const fs = require('fs');
const path = require('path');

console.log('🔧 Applying grievance update fix...');

// Path to the main admin.js file
const adminJsPath = path.join(__dirname, 'routes', 'admin.js');

// Check if the file exists
if (!fs.existsSync(adminJsPath)) {
  console.error('❌ Error: admin.js not found at', adminJsPath);
  process.exit(1);
}

try {
  // Read the admin.js file
  let adminJsContent = fs.readFileSync(adminJsPath, 'utf8');
  console.log('✅ admin.js file loaded');

  // Read the fix file
  const fixPath = path.join(__dirname, 'routes', 'grievance_update_fix.js');
  if (!fs.existsSync(fixPath)) {
    console.error('❌ Error: grievance_update_fix.js not found');
    process.exit(1);
  }

  const fixContent = fs.readFileSync(fixPath, 'utf8');
  console.log('✅ Fix file loaded');

  // Extract the route handler from the fix file
  const routeHandlerMatch = fixContent.match(/router\.put\('\/grievances\/:id\/update-with-images'[\s\S]*?\}\);/);
  if (!routeHandlerMatch) {
    console.error('❌ Error: Could not extract route handler from fix file');
    process.exit(1);
  }

  const routeHandler = routeHandlerMatch[0];
  console.log('✅ Route handler extracted from fix file');

  // Check if the route already exists in admin.js
  if (adminJsContent.includes('/grievances/:id/update-with-images')) {
    console.log('⚠️ Route already exists in admin.js. Backing up and replacing...');
    
    // Create a backup of the current file
    const backupPath = `${adminJsPath}.bak`;
    fs.writeFileSync(backupPath, adminJsContent);
    console.log(`✅ Backup created at ${backupPath}`);
    
    // Find and replace the existing route
    const existingRouteMatch = adminJsContent.match(/router\.put\('\/grievances\/:id\/update-with-images'[\s\S]*?\}\);/);
    if (existingRouteMatch) {
      adminJsContent = adminJsContent.replace(existingRouteMatch[0], routeHandler);
      console.log('✅ Existing route replaced');
    } else {
      console.error('❌ Error: Route marker found but could not match the full route');
      process.exit(1);
    }
  } else {
    // Add the route after the existing updateImageUpload middleware setup
    const insertPoint = adminJsContent.indexOf('updateImageUpload.array(');
    if (insertPoint === -1) {
      console.log('⚠️ Could not find updateImageUpload.array() in admin.js');
      // Try to find a different insertion point - before the module.exports
      const moduleExports = adminJsContent.lastIndexOf('module.exports');
      if (moduleExports === -1) {
        console.error('❌ Error: Could not find insertion point in admin.js');
        process.exit(1);
      }
      
      // Insert before module.exports
      adminJsContent = adminJsContent.slice(0, moduleExports) + 
        "\n// Added JSON-based grievance update endpoint\n" + 
        routeHandler + 
        "\n\n" + 
        adminJsContent.slice(moduleExports);
    } else {
      // Find the end of the current route
      const routeEnd = adminJsContent.indexOf('});', insertPoint);
      if (routeEnd === -1) {
        console.error('❌ Error: Could not find route end');
        process.exit(1);
      }
      
      // Find the next line after the route
      const nextLine = adminJsContent.indexOf('\n', routeEnd) + 1;
      
      // Insert the new route
      adminJsContent = adminJsContent.slice(0, nextLine) + 
        "\n// Added JSON-based grievance update endpoint\n" + 
        routeHandler + 
        "\n\n" + 
        adminJsContent.slice(nextLine);
    }
    console.log('✅ New route added to admin.js');
  }

  // Write the updated admin.js file
  fs.writeFileSync(adminJsPath, adminJsContent);
  console.log('✅ Updated admin.js file written');

  console.log('\n🎉 Grievance update fix applied successfully!');
  console.log('📋 Run the test script to verify:');
  console.log('   node test_grievance_update.js');
} catch (error) {
  console.error('❌ Error applying fix:', error);
  process.exit(1);
}
