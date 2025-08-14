// print_grievance_status_history_schema.js
const sqlite3 = require('sqlite3').verbose();
const dbPath = 'd:/gv/api-server/data/grievance.db';

const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
  if (err) {
    console.error('Failed to open database:', err.message);
    process.exit(1);
  }
});

db.all("PRAGMA table_info('grievanceStatusHistory');", [], (err, rows) => {
  if (err) {
    console.error('Query error:', err.message);
    process.exit(1);
  }
  console.log('grievanceStatusHistory table schema:');
  rows.forEach(row => {
    console.log(row);
  });
  db.close();
});
