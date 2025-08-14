const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const authMiddleware = require('../middleware/auth');
// Use app.get('dbService') instead of direct import
// const dbService = require('../config/database');

const router = express.Router();

// Create uploads directory if it doesn't exist
const uploadDir = process.env.UPLOAD_PATH || './uploads';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const fileType = file.mimetype.startsWith('image/') ? 'images' : 'audio';
    const typeDir = path.join(uploadDir, fileType);
    
    if (!fs.existsSync(typeDir)) {
      fs.mkdirSync(typeDir, { recursive: true });
    }
    
    cb(null, typeDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, file.fieldname + '-' + uniqueSuffix + extension);
  }
});

const fileFilter = (req, file, cb) => {
  // Allow images and audio files
  if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('audio/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image and audio files are allowed'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024, // 10MB default
  }
});

// Upload single file
router.post('/single', authMiddleware, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        error: 'No file uploaded',
        message: 'Please select a file to upload'
      });
    }

    const { grievance_id } = req.body;
    
    if (!grievance_id) {
      return res.status(400).json({
        error: 'Missing grievance ID',
        message: 'Grievance ID is required'
      });
    }

    // Determine file type
    const fileType = req.file.mimetype.startsWith('image/') ? 'image' : 'audio';
    
    // Save file info to database
    const result = await dbService.executeQuery(`
      INSERT INTO MediaAttachments (grievance_id, file_name, file_path, file_type, file_size, mime_type)
      OUTPUT INSERTED.attachment_id
      VALUES (@grievance_id, @file_name, @file_path, @file_type, @file_size, @mime_type)
    `, {
      grievance_id: parseInt(grievance_id),
      file_name: req.file.originalname,
      file_path: req.file.path,
      file_type: fileType,
      file_size: req.file.size,
      mime_type: req.file.mimetype
    });

    const attachmentId = result.recordset[0].attachment_id;

    res.json({
      success: true,
      message: 'File uploaded successfully',
      file: {
        attachment_id: attachmentId,
        file_name: req.file.originalname,
        file_type: fileType,
        file_size: req.file.size,
        file_url: `/uploads/${fileType}s/${req.file.filename}`
      }
    });

  } catch (error) {
    // Delete uploaded file if database save fails
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }

    console.error('File upload error:', error);
    res.status(500).json({
      error: 'Upload failed',
      message: error.message
    });
  }
});

// Upload multiple files
router.post('/multiple', authMiddleware, upload.array('files', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        error: 'No files uploaded',
        message: 'Please select files to upload'
      });
    }

    const { grievance_id } = req.body;
    
    if (!grievance_id) {
      return res.status(400).json({
        error: 'Missing grievance ID',
        message: 'Grievance ID is required'
      });
    }

    const uploadedFiles = [];
    const errors = [];

    // Process each file
    for (const file of req.files) {
      try {
        const fileType = file.mimetype.startsWith('image/') ? 'image' : 'audio';
        
        // Save file info to database
        const result = await dbService.executeQuery(`
          INSERT INTO MediaAttachments (grievance_id, file_name, file_path, file_type, file_size, mime_type)
          OUTPUT INSERTED.attachment_id
          VALUES (@grievance_id, @file_name, @file_path, @file_type, @file_size, @mime_type)
        `, {
          grievance_id: parseInt(grievance_id),
          file_name: file.originalname,
          file_path: file.path,
          file_type: fileType,
          file_size: file.size,
          mime_type: file.mimetype
        });

        const attachmentId = result.recordset[0].attachment_id;

        uploadedFiles.push({
          attachment_id: attachmentId,
          file_name: file.originalname,
          file_type: fileType,
          file_size: file.size,
          file_url: `/uploads/${fileType}s/${file.filename}`
        });

      } catch (error) {
        errors.push({
          file_name: file.originalname,
          error: error.message
        });
        
        // Delete failed upload file
        if (fs.existsSync(file.path)) {
          fs.unlinkSync(file.path);
        }
      }
    }

    res.json({
      success: true,
      message: `${uploadedFiles.length} files uploaded successfully`,
      uploaded_files: uploadedFiles,
      errors: errors.length > 0 ? errors : undefined
    });

  } catch (error) {
    // Delete all uploaded files if there's a general error
    if (req.files) {
      req.files.forEach(file => {
        if (fs.existsSync(file.path)) {
          fs.unlinkSync(file.path);
        }
      });
    }

    console.error('Multiple file upload error:', error);
    res.status(500).json({
      error: 'Upload failed',
      message: error.message
    });
  }
});

// Delete file
router.delete('/:attachment_id', authMiddleware, async (req, res) => {
  try {
    const attachment_id = parseInt(req.params.attachment_id);

    // Get file info from database
    const result = await dbService.executeQuery(`
      SELECT ma.file_path, g.citizen_id
      FROM MediaAttachments ma
      INNER JOIN Grievances g ON ma.grievance_id = g.grievance_id
      WHERE ma.attachment_id = @attachment_id
    `, { attachment_id });

    if (result.recordset.length === 0) {
      return res.status(404).json({
        error: 'File not found',
        message: 'Attachment not found'
      });
    }

    const fileInfo = result.recordset[0];

    // Verify user owns this file
    if (fileInfo.citizen_id !== req.user.citizen_id) {
      return res.status(403).json({
        error: 'Access denied',
        message: 'You can only delete your own files'
      });
    }

    // Delete from database
    await dbService.executeQuery(
      'DELETE FROM MediaAttachments WHERE attachment_id = @attachment_id',
      { attachment_id }
    );

    // Delete physical file
    if (fs.existsSync(fileInfo.file_path)) {
      fs.unlinkSync(fileInfo.file_path);
    }

    res.json({
      success: true,
      message: 'File deleted successfully'
    });

  } catch (error) {
    console.error('File delete error:', error);
    res.status(500).json({
      error: 'Delete failed',
      message: error.message
    });
  }
});

// Error handling middleware for multer
router.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        error: 'File too large',
        message: 'File size exceeds the maximum limit'
      });
    }
    if (error.code === 'LIMIT_FILE_COUNT') {
      return res.status(400).json({
        error: 'Too many files',
        message: 'Maximum 5 files can be uploaded at once'
      });
    }
  }
  
  if (error.message === 'Only image and audio files are allowed') {
    return res.status(400).json({
      error: 'Invalid file type',
      message: 'Only image and audio files are allowed'
    });
  }

  next(error);
});

module.exports = router;
