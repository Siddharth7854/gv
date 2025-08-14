// API route for updating grievance status with progress photos from JSON
// This fixes the issue with updating grievances from the admin panel

const express = require('express');
const router = express.Router();
const authenticateAdmin = require('../middleware/adminAuth');

// Add this new route to handle updating grievance status with JSON progress photos
router.put('/grievances/:id/update-with-images', authenticateAdmin, async (req, res) => {
  try {
    const dbService = req.app.get('dbService');  
    const { id } = req.params;
    const { status, comments, progress_photos } = req.body;
    const imageUrls = progress_photos || [];
    
    console.log(`🔄 Updating grievance ${id} status to: ${status} with ${imageUrls.length} images`);
    console.log(`💬 Comments: ${comments || 'none'}`);
    console.log(`📸 Image URLs: ${imageUrls.join(', ')}`);
    
    // Get current status before updating
    const currentResult = await dbService.query(
      `SELECT status FROM grievances WHERE grievanceId = ?`, 
      [id]
    );
    
    if (currentResult.length === 0) {
      console.log(`❌ Grievance ${id} not found`);
      return res.status(404).json({ error: 'Grievance not found' });
    }
    
    const currentStatus = currentResult[0].status;
    console.log(`📊 Current status: ${currentStatus}, New status: ${status}`);
    
    // Update grievance status
    let query = `UPDATE grievances SET status = ?, updatedAt = CURRENT_TIMESTAMP`;
    let params = [status];
    
    if (status === 'Resolved') {
      query += `, resolvedAt = CURRENT_TIMESTAMP`;
    }
    
    if (comments) {
      query += `, adminComments = ?`;
      params.push(comments);
    }
    
    query += ` WHERE grievanceId = ?`;
    params.push(id);
    
    console.log(`📝 SQL Query: ${query}`, params);
    
    await dbService.run(query, params);

    // Insert status history with images
    const adminName = req.admin ? (req.admin.fullName || req.admin.username || 'Admin') : 'Admin';
    const changeReason = comments || `Status updated to ${status} by admin`;
    
    // Join image URLs for storage
    const imageUrlsStr = imageUrls.join(',');
    
    await dbService.run(`
      INSERT INTO grievanceStatusHistory (grievanceId, previousStatus, newStatus, changedBy, changeReason, changedAt, imageUrls)
      VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
    `, [id, currentStatus, status, adminName, changeReason, imageUrlsStr]);

    console.log(`✅ Grievance ${id} status updated successfully with ${imageUrls.length} images`);
    
    // Fetch the updated grievance for verification
    const updatedRow = await dbService.query(
      `SELECT status, resolvedAt, adminComments FROM grievances WHERE grievanceId = ?`, 
      [id]
    );
    
    console.log(`✅ Updated row:`, updatedRow[0]);

    res.json({ 
      message: 'Grievance status updated successfully with images',
      grievanceId: id,
      newStatus: status,
      previousStatus: currentStatus,
      comments: comments || null,
      imageCount: imageUrls.length,
      changedBy: adminName
    });
  } catch (error) {
    console.error('❌ Update grievance with images error:', error);
    res.status(500).json({ error: 'Failed to update grievance status' });
  }
});

module.exports = router;
