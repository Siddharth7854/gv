// create_grievance_status_history_table.js
const sqlite3 = require('sqlite3').verbose();
const dbPath = 'd:/gv/api-server/data/grievance.db';

const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READWRITE, (err) => {
  if (err) {
    console.error('Failed to open database:', err.message);
    process.exit(1);
  }
});

const createTableSQL = `
CREATE TABLE IF NOT EXISTS grievanceStatusHistory (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  grievanceId TEXT NOT NULL,
  previousStatus TEXT,
  newStatus TEXT,
  changedBy TEXT,
  changeReason TEXT,
  changedAt TEXT DEFAULT CURRENT_TIMESTAMP,
  imageUrls TEXT
);
`;

db.run(createTableSQL, (err) => {
  if (err) {
    console.error('Failed to create table:', err.message);
    process.exit(1);
  }
  console.log('✅ grievanceStatusHistory table created or already exists.');
  db.close();
});
