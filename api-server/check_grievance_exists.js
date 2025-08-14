// check_grievance_exists.js
const sqlite3 = require('sqlite3').verbose();
const dbPath = 'd:/gv/api-server/data/grievance.db';
const grievanceId = process.argv[2] || 'GRV_1755128211741_a94505dd';

const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
  if (err) {
    console.error('Failed to open database:', err.message);
    process.exit(1);
  }
});

db.get('SELECT * FROM grievances WHERE grievanceId = ?', [grievanceId], (err, row) => {
  if (err) {
    console.error('Query error:', err.message);
    process.exit(1);
  }
  if (row) {
    console.log('✅ Grievance found:', row);
  } else {
    console.log('❌ Grievance not found:', grievanceId);
  }
  db.close();
});
