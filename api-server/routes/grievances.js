const express = require('express');
const { body, validationResult } = require('express-validator');
// Use app.get('dbService') instead of direct import
// const dbService = require('../config/database');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Submit new grievance
router.post('/', authMiddleware, [
  body('category_id').isInt({ min: 1 }).withMessage('Valid category is required'),
  body('title').trim().isLength({ min: 5, max: 200 }).withMessage('Title must be between 5 and 200 characters'),
  body('description').trim().isLength({ min: 20 }).withMessage('Description must be at least 20 characters'),
  body('priority').isIn(['Low', 'Medium', 'High', 'Critical']).withMessage('Invalid priority level'),
  body('urgency').isIn(['Normal', 'Urgent', 'Emergency']).withMessage('Invalid urgency level'),
  body('location_latitude').optional().isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
  body('location_longitude').optional().isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        details: errors.array()
      });
    }

    const {
      category_id,
      title,
      description,
      priority,
      urgency,
      location_latitude,
      location_longitude,
      location_address,
      image_paths,
      audio_paths
    } = req.body;

    const citizen_id = req.user.citizen_id;
    const ip_address = req.ip || req.connection.remoteAddress;
    const user_agent = req.headers['user-agent'];

    // Check if user has grievance submission restrictions
    const controlsResult = await dbService.executeQuery(`
      SELECT control_type, reason 
      FROM UserTimelineControl 
      WHERE citizen_id = @citizen_id 
      AND is_active = 1 
      AND control_type = 'Grievance_Restriction'
      AND (end_date IS NULL OR end_date > GETDATE())
    `, { citizen_id });

    if (controlsResult.recordset.length > 0) {
      const control = controlsResult.recordset[0];
      
      // Log blocked submission attempt
      await dbService.executeQuery(
        'EXEC SP_LogUserActivity @citizen_id, @activity_type, @activity_description, @ip_address, @user_agent, @session_id, @status',
        {
          citizen_id,
          activity_type: 'Grievance_Submit',
          activity_description: `Grievance submission blocked: ${control.reason}`,
          ip_address,
          user_agent,
          session_id: null,
          status: 'Blocked'
        }
      );

      return res.status(403).json({
        error: 'Submission Restricted',
        message: `Grievance submission has been restricted. Reason: ${control.reason}`,
        control_type: control.control_type
      });
    }

    // Submit grievance using stored procedure
    const result = await dbService.executeStoredProcedure('sp_InsertGrievance', {
      citizen_id,
      category_id,
      title,
      description,
      priority,
      urgency,
      location_latitude: location_latitude || null,
      location_longitude: location_longitude || null,
      location_address: location_address || null
    });

    const grievanceData = result.recordset[0];

    // Handle media files (images and audio) if provided
    if (image_paths && Array.isArray(image_paths) && image_paths.length > 0) {
      console.log(`📷 Processing ${image_paths.length} images for grievance ${grievanceData.grievance_id}`);
      
      for (let i = 0; i < image_paths.length; i++) {
        const imagePath = image_paths[i];
        console.log(`📷 Image ${i + 1}: ${imagePath}`);
        
        try {
          // Extract filename from path
          const fileName = imagePath.split('/').pop() || imagePath.split('\\').pop() || `image_${i + 1}.jpg`;
          
          // Insert into MediaAttachments table
          await dbService.executeQuery(`
            INSERT INTO MediaAttachments 
            (grievance_id, file_name, file_path, file_type, mime_type, uploaded_at)
            VALUES (@grievance_id, @file_name, @file_path, @file_type, @mime_type, GETDATE())
          `, {
            grievance_id: grievanceData.grievance_id,
            file_name: fileName,
            file_path: imagePath,
            file_type: 'image',
            mime_type: 'image/jpeg' // Default, could be improved to detect actual mime type
          });
          
          console.log(`✅ Image ${i + 1} saved to database: ${fileName}`);
        } catch (mediaError) {
          console.error(`❌ Error saving image ${i + 1}:`, mediaError);
        }
      }
    }

    if (audio_paths && Array.isArray(audio_paths) && audio_paths.length > 0) {
      console.log(`🎵 Processing ${audio_paths.length} audio files for grievance ${grievanceData.grievance_id}`);
      
      for (let i = 0; i < audio_paths.length; i++) {
        const audioPath = audio_paths[i];
        console.log(`🎵 Audio ${i + 1}: ${audioPath}`);
        
        try {
          // Extract filename from path
          const fileName = audioPath.split('/').pop() || audioPath.split('\\').pop() || `audio_${i + 1}.mp3`;
          
          // Insert into MediaAttachments table
          await dbService.executeQuery(`
            INSERT INTO MediaAttachments 
            (grievance_id, file_name, file_path, file_type, mime_type, uploaded_at)
            VALUES (@grievance_id, @file_name, @file_path, @file_type, @mime_type, GETDATE())
          `, {
            grievance_id: grievanceData.grievance_id,
            file_name: fileName,
            file_path: audioPath,
            file_type: 'audio',
            mime_type: 'audio/mpeg' // Default, could be improved to detect actual mime type
          });
          
          console.log(`✅ Audio ${i + 1} saved to database: ${fileName}`);
        } catch (mediaError) {
          console.error(`❌ Error saving audio ${i + 1}:`, mediaError);
        }
      }
    }

    // Log successful grievance submission
    await dbService.executeQuery(
      'EXEC SP_LogUserActivity @citizen_id, @activity_type, @activity_description, @ip_address, @user_agent, @session_id, @status',
      {
        citizen_id,
        activity_type: 'Grievance_Submit',
        activity_description: `Submitted grievance: ${title} (${grievanceData.grievance_number})`,
        ip_address,
        user_agent,
        session_id: null,
        status: 'Success'
      }
    );

    console.log(`✅ Grievance submitted by citizen ${citizen_id}: ${grievanceData.grievance_number}`);

    // Count media files for response
    const imageCount = (image_paths && Array.isArray(image_paths)) ? image_paths.length : 0;
    const audioCount = (audio_paths && Array.isArray(audio_paths)) ? audio_paths.length : 0;

    res.status(201).json({
      success: true,
      message: 'Grievance submitted successfully',
      grievance: {
        grievance_id: grievanceData.grievance_id,
        grievance_number: grievanceData.grievance_number,
        status: 'Submitted',
        submitted_at: new Date(),
        media_files: {
          images: imageCount,
          audio: audioCount,
          total: imageCount + audioCount
        }
      }
    });

  } catch (error) {
    console.error('Grievance submission error:', error);
    res.status(500).json({
      error: 'Submission failed',
      message: error.message
    });
  }
});

// Get grievances by citizen
router.get('/citizen/:citizen_id', authMiddleware, async (req, res) => {
  try {
    const citizen_id = parseInt(req.params.citizen_id);
    
    // Verify user can only access their own grievances
    if (citizen_id !== req.user.citizen_id) {
      return res.status(403).json({
        error: 'Access denied',
        message: 'You can only access your own grievances'
      });
    }

    const result = await dbService.executeQuery(`
      SELECT 
        g.grievance_id,
        g.grievance_number,
        g.citizen_id,
        g.category_id,
        g.title,
        g.description,
        g.priority,
        g.urgency,
        g.status,
        g.location_latitude,
        g.location_longitude,
        g.location_address,
        g.submitted_at,
        g.updated_at,
        g.resolved_at,
        g.assigned_to,
        g.resolution_notes,
        c.category_name
      FROM Grievances g
      INNER JOIN Categories c ON g.category_id = c.category_id
      WHERE g.citizen_id = @citizen_id
      ORDER BY g.submitted_at DESC
    `, { citizen_id });

    res.json({
      success: true,
      grievances: result.recordset
    });

  } catch (error) {
    console.error('Fetch grievances error:', error);
    res.status(500).json({
      error: 'Fetch failed',
      message: error.message
    });
  }
});

// Get grievance by ID
router.get('/:grievance_id', authMiddleware, async (req, res) => {
  try {
    const grievance_id = parseInt(req.params.grievance_id);
    console.log(`[GRIEVANCE DEBUG] Fetching grievance ${grievance_id} for user ${req.user.citizen_id}`);

    // Modified query to include citizen_id from the table
    const result = await dbService.executeQuery(`
      SELECT 
        g.grievance_id,
        g.grievance_number,
        g.citizen_id,
        g.title,
        g.description,
        g.priority,
        g.urgency,
        g.status,
        g.location_latitude,
        g.location_longitude,
        g.location_address,
        g.submitted_at,
        g.updated_at,
        g.resolved_at,
        g.assigned_to,
        g.resolution_notes,
        g.admin_comments,
        c.full_name AS citizen_name,
        c.phone AS citizen_phone,
        c.email AS citizen_email,
        c.district,
        c.block,
        c.ward,
        cat.category_name,
        cat.description AS category_description
      FROM Grievances g
      INNER JOIN Citizens c ON g.citizen_id = c.citizen_id
      INNER JOIN Categories cat ON g.category_id = cat.category_id
      WHERE g.grievance_id = @grievance_id
    `, { grievance_id });

    console.log(`[GRIEVANCE DEBUG] Query result count: ${result.recordset.length}`);

    if (result.recordset.length === 0) {
      console.log(`[GRIEVANCE DEBUG] Grievance ${grievance_id} not found`);
      return res.status(404).json({
        error: 'Not found',
        message: 'Grievance not found'
      });
    }

    const grievance = result.recordset[0];
    console.log(`[GRIEVANCE DEBUG] Found grievance: citizen_id=${grievance.citizen_id}, user_id=${req.user.citizen_id}`);

    // Verify user can only access their own grievances
    if (grievance.citizen_id !== req.user.citizen_id) {
      console.log(`[GRIEVANCE DEBUG] Access denied: grievance.citizen_id=${grievance.citizen_id} !== req.user.citizen_id=${req.user.citizen_id}`);
      return res.status(403).json({
        error: 'Access denied',
        message: 'You can only access your own grievances'
      });
    }

    console.log(`[GRIEVANCE DEBUG] Access granted for grievance ${grievance_id}`);
    

    // Get media attachments
    const mediaResult = await dbService.executeQuery(`
      SELECT attachment_id, file_name, file_path, file_type, file_size, uploaded_at
      FROM MediaAttachments
      WHERE grievance_id = @grievance_id
      ORDER BY uploaded_at ASC
    `, { grievance_id });

    // Get status history
    const historyResult = await dbService.executeQuery(`
      SELECT history_id, previous_status, new_status, changed_by, change_reason, changed_at
      FROM GrievanceStatusHistory
      WHERE grievance_id = @grievance_id
      ORDER BY changed_at ASC
    `, { grievance_id });

    res.json({
      success: true,
      grievance,
      media_attachments: mediaResult.recordset,
      status_history: historyResult.recordset
    });

  } catch (error) {
    console.error('Fetch grievance details error:', error);
    res.status(500).json({
      error: 'Fetch failed',
      message: error.message
    });
  }
});

// Update grievance status (admin only - for future use)
router.patch('/:grievance_id/status', authMiddleware, async (req, res) => {
  try {
    const grievance_id = parseInt(req.params.grievance_id);
    const { status, resolution_notes, assigned_to } = req.body;

    if (!['Submitted', 'Under Review', 'In Progress', 'Resolved', 'Closed', 'Rejected'].includes(status)) {
      return res.status(400).json({
        error: 'Invalid status',
        message: 'Status must be one of: Submitted, Under Review, In Progress, Resolved, Closed, Rejected'
      });
    }

    // Get current grievance
    const currentResult = await dbService.executeQuery(
      'SELECT status FROM Grievances WHERE grievance_id = @grievance_id',
      { grievance_id }
    );

    if (currentResult.recordset.length === 0) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Grievance not found'
      });
    }

    const currentStatus = currentResult.recordset[0].status;

    // Update grievance using transaction
    await dbService.transaction(async (request) => {
      // Update grievance
      await request
        .input('grievance_id', grievance_id)
        .input('status', status)
        .input('resolution_notes', resolution_notes || null)
        .input('assigned_to', assigned_to || null)
        .input('resolved_at', status === 'Resolved' ? new Date() : null)
        .query(`
          UPDATE Grievances 
          SET status = @status, 
              resolution_notes = @resolution_notes, 
              assigned_to = @assigned_to,
              resolved_at = @resolved_at,
              updated_at = GETDATE()
          WHERE grievance_id = @grievance_id
        `);

      // Insert status history
      await request
        .input('previous_status', currentStatus)
        .input('new_status', status)
        .input('changed_by', req.user.phone || 'System')
        .input('change_reason', resolution_notes || 'Status updated')
        .query(`
          INSERT INTO GrievanceStatusHistory (grievance_id, previous_status, new_status, changed_by, change_reason, changed_at)
          VALUES (@grievance_id, @previous_status, @new_status, @changed_by, @change_reason, GETDATE())
        `);
    });

    res.json({
      success: true,
      message: 'Grievance status updated successfully'
    });

  } catch (error) {
    console.error('Status update error:', error);
    res.status(500).json({
      error: 'Update failed',
      message: error.message
    });
  }
});

// Get grievance status history (timeline)
router.get('/:grievance_id/timeline', authMiddleware, async (req, res) => {
  try {
    const grievance_id = parseInt(req.params.grievance_id);
    console.log(`[TIMELINE DEBUG] Fetching timeline for grievance ${grievance_id} by user ${req.user.citizen_id}`);

    // First verify user can access this grievance
    const grievanceResult = await dbService.executeQuery(`
      SELECT citizen_id FROM Grievances WHERE grievance_id = @grievance_id
    `, { grievance_id });

    if (grievanceResult.recordset.length === 0) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Grievance not found'
      });
    }

    const grievance = grievanceResult.recordset[0];
    if (grievance.citizen_id !== req.user.citizen_id) {
      return res.status(403).json({
        error: 'Access denied',
        message: 'You can only access timeline for your own grievances'
      });
    }

    // Get status history
    const timelineResult = await dbService.executeQuery(`
      SELECT 
        history_id,
        previous_status,
        new_status,
        changed_by,
        change_reason,
        changed_at,
        image_urls
      FROM GrievanceStatusHistory
      WHERE grievance_id = @grievance_id
      ORDER BY changed_at ASC
    `, { grievance_id });

    console.log(`[TIMELINE DEBUG] Found ${timelineResult.recordset.length} timeline entries`);

    res.json({
      success: true,
      timeline: timelineResult.recordset
    });

  } catch (error) {
    console.error('Timeline fetch error:', error);
    res.status(500).json({
      error: 'Timeline fetch failed',
      message: error.message
    });
  }
});

// Delete grievance (only by owner and only if status is 'Submitted')
router.delete('/:grievance_id', authMiddleware, async (req, res) => {
  try {
    const grievance_id = parseInt(req.params.grievance_id);
    console.log(`[DELETE GRIEVANCE] User ${req.user.citizen_id} requesting to delete grievance ${grievance_id}`);

    // First check if grievance exists and belongs to user
    const grievanceResult = await dbService.executeQuery(`
      SELECT citizen_id, status FROM Grievances WHERE grievance_id = @grievance_id
    `, { grievance_id });

    if (grievanceResult.recordset.length === 0) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Grievance not found'
      });
    }

    const grievance = grievanceResult.recordset[0];

    // Check if user owns this grievance
    if (grievance.citizen_id !== req.user.citizen_id) {
      return res.status(403).json({
        error: 'Access denied',
        message: 'You can only delete your own grievances'
      });
    }

    // Check if grievance can be deleted (only 'Submitted' status)
    if (grievance.status.toLowerCase() !== 'submitted') {
      return res.status(400).json({
        error: 'Cannot delete',
        message: 'Only grievances with "Submitted" status can be deleted'
      });
    }

    // Delete in transaction (this will cascade delete media attachments and status history)
    await dbService.transaction(async (request) => {
      // Delete media attachments first
      await request
        .input('grievance_id', grievance_id)
        .query('DELETE FROM MediaAttachments WHERE grievance_id = @grievance_id');

      // Delete status history
      await request
        .query('DELETE FROM GrievanceStatusHistory WHERE grievance_id = @grievance_id');

      // Delete the grievance
      await request
        .query('DELETE FROM Grievances WHERE grievance_id = @grievance_id');
    });

    console.log(`[DELETE GRIEVANCE] Successfully deleted grievance ${grievance_id} by user ${req.user.citizen_id}`);

    res.json({
      success: true,
      message: 'Grievance deleted successfully'
    });

  } catch (error) {
    console.error('Delete grievance error:', error);
    res.status(500).json({
      error: 'Delete failed',
      message: error.message
    });
  }
});

module.exports = router;
