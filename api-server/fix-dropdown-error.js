// fix_dropdown_error.js
// This script checks for potential dropdown errors in the Flutter app

const fs = require('fs');
const path = require('path');

// Path to the admin grievances screen
const filePath = path.join(__dirname, '..', 'lib', 'screens', 'admin', 'admin_grievances_screen.dart');

// Check if file exists
if (!fs.existsSync(filePath)) {
  console.error(`❌ File not found: ${filePath}`);
  process.exit(1);
}

// Read file content
let content = fs.readFileSync(filePath, 'utf8');

console.log('📝 Analyzing dropdown usage in admin_grievances_screen.dart...');

// Look for the status options definition
const statusOptionsMatch = content.match(/final List<String> _statusOptions = \[([\s\S]*?)\];/);
if (!statusOptionsMatch) {
  console.error('❌ Could not find status options definition');
  process.exit(1);
}

// Extract status options
const statusOptions = statusOptionsMatch[1]
  .trim()
  .split(',')
  .map(option => option.trim())
  .filter(option => option.startsWith("'") || option.startsWith('"'))
  .map(option => option.replace(/['"]/g, '').trim());

console.log('✅ Found status options:', statusOptions);

// Check for initialization of _selectedStatus
const initMatch = content.match(/_selectedStatus = widget\.grievance\['status'\] \?\? ['"]([^'"]+)['"]/);
if (!initMatch) {
  console.error('❌ Could not find initialization of _selectedStatus');
  process.exit(1);
}

const defaultStatus = initMatch[1];
console.log(`✅ Default status: "${defaultStatus}"`);

// Verify default status is in the options list
if (!statusOptions.includes(defaultStatus)) {
  console.error(`❌ Default status "${defaultStatus}" is not in status options: ${statusOptions.join(', ')}`);
  console.log('🔄 Adding it to the options to fix dropdown error...');
  
  // Fix: Update the status options to include the default
  const updatedOptions = [...new Set([...statusOptions, defaultStatus])].sort();
  console.log('✅ Updated status options:', updatedOptions);
  
  // Format the new options list
  const formattedOptions = updatedOptions
    .map(option => `    '${option}'`)
    .join(',\n');
  
  // Replace the old options list with the new one
  const newOptionsText = `final List<String> _statusOptions = [\n${formattedOptions},\n  ];`;
  content = content.replace(/final List<String> _statusOptions = \[([\s\S]*?)\];/, newOptionsText);
  
  // Write the updated content back to the file
  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`✅ Updated ${filePath} with fixed dropdown options`);
  
  // Also check the kStandardGrievanceStatuses in admin_providers.dart
  const providersPath = path.join(__dirname, '..', 'lib', 'providers', 'admin_providers.dart');
  if (fs.existsSync(providersPath)) {
    console.log(`📝 Also checking standard status list in admin_providers.dart...`);
    let providersContent = fs.readFileSync(providersPath, 'utf8');
    
    const standardStatusesMatch = providersContent.match(/const List<String> kStandardGrievanceStatuses = \[([\s\S]*?)\];/);
    if (standardStatusesMatch) {
      const standardStatuses = standardStatusesMatch[1]
        .trim()
        .split(',')
        .map(option => option.trim())
        .filter(option => option.startsWith("'") || option.startsWith('"'))
        .map(option => option.replace(/['"]/g, '').trim());
      
      console.log('✅ Found standard statuses:', standardStatuses);
      
      // Check if default status is in standard statuses
      if (!standardStatuses.includes(defaultStatus)) {
        console.log(`🔄 Adding "${defaultStatus}" to standard status list...`);
        
        // Create updated standard statuses list
        const updatedStandardStatuses = [...new Set([...standardStatuses, defaultStatus])].sort();
        const formattedStandardStatuses = updatedStandardStatuses
          .map(status => `  '${status}'`)
          .join(',\n');
        
        // Replace the old standard statuses list
        const newStandardStatusesText = `const List<String> kStandardGrievanceStatuses = [\n${formattedStandardStatuses},\n];`;
        providersContent = providersContent.replace(
          /const List<String> kStandardGrievanceStatuses = \[([\s\S]*?)\];/, 
          newStandardStatusesText
        );
        
        // Write updated content
        fs.writeFileSync(providersPath, providersContent, 'utf8');
        console.log(`✅ Updated ${providersPath} with consistent status list`);
      } else {
        console.log(`✅ Standard status list already includes "${defaultStatus}"`);
      }
    }
  }
  
  console.log('\n✅ FIX COMPLETE: The dropdown error should now be resolved.');
  console.log('📋 To verify the fix:');
  console.log('   1. Restart the Flutter app');
  console.log('   2. Navigate to the admin grievances screen');
  console.log('   3. Try to update a grievance status');
} else {
  console.log(`✅ Default status "${defaultStatus}" is already in status options - no fix needed`);
}
