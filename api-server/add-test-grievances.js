const SQLiteService = require('./config/sqlite');
const { v4: uuidv4 } = require('uuid');
const dbService = new SQLiteService();

async function addTestGrievances() {
  try {
    await dbService.connect();
    
    // Get existing users
    const users = await dbService.query('SELECT userId FROM users LIMIT 3');
    if (users.length === 0) {
      console.log('No users found in the database. Please add users first.');
      return;
    }
    
    // Sample grievance categories
    const categories = [
      'Water Supply',
      'Electricity',
      'Road Maintenance',
      'Sanitation',
      'Healthcare',
      'Education',
      'Law and Order',
      'Municipal Issues'
    ];
    
    // Sample grievance titles
    const titles = [
      'Water not available in my area',
      'Power outage for last 24 hours',
      'Pothole on main road',
      'Garbage not collected for a week',
      'Streetlight not working',
      'Drainage overflow',
      'Noise pollution',
      'Illegal construction'
    ];
    
    // Sample grievance descriptions
    const descriptions = [
      'There is no water supply in my area since yesterday morning. Please resolve this issue urgently.',
      'Power supply is interrupted frequently in our area. It affects daily activities and work.',
      'The road has large potholes making it difficult for vehicles to pass. It is dangerous for two-wheelers.',
      'Garbage bins are overflowing and not cleaned regularly. It is causing bad smell and health issues.',
      'The streetlight near my house is not working for the past week, making it unsafe at night.',
      'The drainage system is blocked causing overflow on the streets. It is a health hazard.',
      'There is too much noise from nearby construction site even during night hours.',
      'There is an illegal construction happening in the neighborhood without proper permits.'
    ];
    
    // Sample statuses
    const statuses = ['pending', 'in_progress', 'resolved', 'rejected'];
    
    // Sample priorities
    const priorities = ['low', 'medium', 'high', 'urgent'];
    
    // Add 10 test grievances
    const grievancesToAdd = 10;
    
    console.log(`Adding ${grievancesToAdd} test grievances...`);
    
    for (let i = 0; i < grievancesToAdd; i++) {
      // Pick random values
      const userId = users[Math.floor(Math.random() * users.length)].userId;
      const categoryIndex = Math.floor(Math.random() * categories.length);
      const category = categories[categoryIndex];
      const title = titles[Math.floor(Math.random() * titles.length)];
      const description = descriptions[Math.floor(Math.random() * descriptions.length)];
      const status = statuses[Math.floor(Math.random() * statuses.length)];
      const priority = priorities[Math.floor(Math.random() * priorities.length)];
      
      // Generate a unique ID for the grievance
      const grievanceId = `GRV_${Date.now()}_${uuidv4().substring(0, 8)}`;
      
      // Generate created and updated dates
      const now = new Date();
      const createdAt = new Date(now.getTime() - Math.floor(Math.random() * 30) * 24 * 60 * 60 * 1000); // Random date within last 30 days
      
      // Insert the grievance
      await dbService.run(
        `INSERT INTO grievances (
          grievanceId, 
          userId, 
          title, 
          description, 
          category, 
          priority, 
          status, 
          createdAt
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          grievanceId,
          userId,
          title,
          description,
          category,
          priority,
          status,
          createdAt.toISOString()
        ]
      );
      
      console.log(`Added grievance ${i+1}/${grievancesToAdd}: ${grievanceId}`);
    }
    
    console.log('\nVerifying grievances count:');
    const count = await dbService.query('SELECT COUNT(*) as count FROM grievances');
    console.log(`Total grievances in database: ${count[0].count}`);
    
  } catch (error) {
    console.error('Error adding test grievances:', error);
  } finally {
    await dbService.close();
  }
}

addTestGrievances();
