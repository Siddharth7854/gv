// Fix for admin login freezing issue
// This script applies the necessary fixes to the admin login functionality

const path = require('path');
const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const sqlite3 = require('sqlite3').verbose();

// Connect to database
const db = new sqlite3.Database(path.join(__dirname, 'database.db'));

// Initialize Express server for testing
const app = express();
app.use(express.json());

// Set JWT secret
const JWT_SECRET = process.env.JWT_SECRET || 'default_jwt_secret_for_development';

// Define admin login endpoint (fixed version)
app.post('/api/admin/admin-login', (req, res) => {
  console.log('🔒 Admin login attempt:', req.body.username);
  
  const { username, password } = req.body;
  
  // Validate input
  if (!username || !password) {
    return res.status(400).json({ 
      success: false, 
      error: 'Username and password are required' 
    });
  }

  // Query for admin (using lowercase table name)
  const query = 'SELECT * FROM admins WHERE username = ?';
  
  db.get(query, [username], (err, admin) => {
    if (err) {
      console.error('❌ Database error:', err);
      return res.status(500).json({ 
        success: false, 
        error: 'Internal server error' 
      });
    }
    
    if (!admin) {
      console.log('❌ Admin not found:', username);
      return res.status(401).json({ 
        success: false, 
        error: 'Invalid credentials' 
      });
    }
    
    // Compare password
    bcrypt.compare(password, admin.password, (err, isMatch) => {
      if (err) {
        console.error('❌ Password comparison error:', err);
        return res.status(500).json({ 
          success: false, 
          error: 'Internal server error' 
        });
      }
      
      if (!isMatch) {
        console.log('❌ Invalid password for admin:', username);
        return res.status(401).json({ 
          success: false, 
          error: 'Invalid credentials' 
        });
      }
      
      // Generate JWT token with adminId in payload
      const token = jwt.sign(
        { 
          adminId: admin.id,
          username: admin.username,
          role: admin.role || 'admin'
        }, 
        JWT_SECRET, 
        { expiresIn: '24h' }
      );
      
      console.log('✅ Admin login successful:', username);
      console.log('🎟️ Token generated with adminId:', admin.id);
      
      // Return success with token and admin data (except password)
      const { password: _, ...adminData } = admin;
      
      res.json({
        success: true,
        token,
        ...adminData
      });
    });
  });
});

// Define dashboard stats endpoint (fixed version)
app.get('/api/admin/dashboard-stats', (req, res) => {
  console.log('📊 Dashboard stats request');
  
  // Get auth header
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.log('❌ Missing or invalid Authorization header');
    return res.status(401).json({ 
      success: false, 
      error: 'Unauthorized' 
    });
  }
  
  const token = authHeader.split(' ')[1];
  
  // Verify token
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    console.log('✅ Token verified for admin ID:', decoded.adminId);
    
    // Check if it has adminId (our auth property)
    if (!decoded.adminId) {
      console.log('❌ Token missing adminId');
      return res.status(401).json({ 
        success: false, 
        error: 'Invalid token' 
      });
    }
    
    // Get dashboard stats (mock data for quick test)
    const stats = {
      totalGrievances: 0,
      totalUsers: 0,
      pendingGrievances: 0,
      resolvedGrievances: 0,
      statusDistribution: [],
      departmentDistribution: [],
      recentActivity: []
    };
    
    // Query for total grievances
    db.get('SELECT COUNT(*) as count FROM grievances', [], (err, result) => {
      if (err) {
        console.error('❌ Error getting grievance count:', err);
      } else if (result) {
        stats.totalGrievances = result.count;
      }
      
      // Query for total users
      db.get('SELECT COUNT(*) as count FROM users', [], (err, result) => {
        if (err) {
          console.error('❌ Error getting user count:', err);
        } else if (result) {
          stats.totalUsers = result.count;
        }
        
        // Query for pending grievances
        db.get("SELECT COUNT(*) as count FROM grievances WHERE status IN ('Submitted', 'Under Review', 'In Progress')", [], (err, result) => {
          if (err) {
            console.error('❌ Error getting pending grievances:', err);
          } else if (result) {
            stats.pendingGrievances = result.count;
          }
          
          // Query for resolved grievances
          db.get("SELECT COUNT(*) as count FROM grievances WHERE status = 'Resolved'", [], (err, result) => {
            if (err) {
              console.error('❌ Error getting resolved grievances:', err);
            } else if (result) {
              stats.resolvedGrievances = result.count;
            }
            
            // Query for status distribution
            db.all('SELECT status, COUNT(*) as count FROM grievances GROUP BY status', [], (err, rows) => {
              if (err) {
                console.error('❌ Error getting status distribution:', err);
              } else if (rows) {
                stats.statusDistribution = rows;
              }
              
              // Query for department distribution
              db.all('SELECT department, COUNT(*) as count FROM grievances GROUP BY department', [], (err, rows) => {
                if (err) {
                  console.error('❌ Error getting department distribution:', err);
                } else if (rows) {
                  stats.departmentDistribution = rows;
                }
                
                // Query for recent activity
                db.all('SELECT * FROM grievances ORDER BY created_at DESC LIMIT 5', [], (err, rows) => {
                  if (err) {
                    console.error('❌ Error getting recent activity:', err);
                  } else if (rows) {
                    stats.recentActivity = rows;
                  }
                  
                  console.log('📊 Dashboard stats compiled');
                  res.json({
                    success: true,
                    data: stats
                  });
                });
              });
            });
          });
        });
      });
    });
    
  } catch (err) {
    console.error('❌ Token verification failed:', err);
    return res.status(401).json({ 
      success: false, 
      error: 'Invalid token' 
    });
  }
});

// Start server for testing
const PORT = 5000;
const server = app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🔗 Test the admin login API: http://localhost:${PORT}/api/admin/admin-login`);
  console.log(`🔗 Test the dashboard stats API: http://localhost:${PORT}/api/admin/dashboard-stats`);
  console.log(`🛠️ Fix for admin login freezing issue applied`);
  console.log(`🔒 Use credentials: username='admin', password='admin123'`);
});

// Close server and database on SIGINT
process.on('SIGINT', () => {
  server.close(() => {
    console.log('Server closed');
    db.close(() => {
      console.log('Database connection closed');
      process.exit(0);
    });
  });
});
