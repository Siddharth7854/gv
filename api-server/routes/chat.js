const express = require('express');
const router = express.Router();
const { authenticateAdmin } = require('../middleware/adminAuth');
const { authenticateUser } = require('../middleware/auth');
// Use app.get('dbService') instead of direct import
// const dbService = require('../config/database');

// ==========================
// ADMIN CHAT ENDPOINTS
// ==========================

// Get all chat conversations for admin dashboard
router.get('/admin/conversations', authenticateAdmin, async (req, res) => {
  try {
    const pool = dbService.getPool();
    
    const result = await pool.request().query(`
      SELECT 
        conversation_id,
        grievance_id,
        citizen_id,
        status,
        conversation_created_at,
        conversation_updated_at,
        grievance_number,
        grievance_title,
        grievance_status,
        user_name,
        user_phone,
        user_email,
        last_message,
        last_message_time,
        last_sender_type,
        unread_count
      FROM vw_ChatConversationSummary
      ORDER BY last_message_time DESC, conversation_updated_at DESC
    `);

    const conversations = result.recordset.map(row => ({
      id: `chat_${row.conversation_id}`,
      conversation_id: row.conversation_id,
      grievance_id: row.grievance_number,
      grievance_title: row.grievance_title,
      grievance_status: row.grievance_status,
      user_name: row.user_name,
      user_id: `user_${row.citizen_id}`,
      user_phone: row.user_phone,
      user_email: row.user_email,
      status: row.status,
      unread_count: row.unread_count || 0,
      last_message: row.last_message || 'No messages yet',
      last_message_time: row.last_message_time || row.conversation_created_at,
      created_at: row.conversation_created_at
    }));

    res.json({
      success: true,
      conversations: conversations
    });

  } catch (error) {
    console.error('❌ Error fetching conversations:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch conversations',
      message: error.message
    });
  }
});

// Get messages for a specific conversation
router.get('/admin/conversations/:conversationId/messages', authenticateAdmin, async (req, res) => {
  try {
    const conversationId = req.params.conversationId.replace('chat_', '');
    const pool = dbService.getPool();
    
    // First check if conversation exists
    const convCheck = await pool.request()
      .input('conversationId', conversationId)
      .query(`
        SELECT conversation_id, grievance_id, citizen_id 
        FROM ChatConversations 
        WHERE conversation_id = @conversationId
      `);
    
    if (convCheck.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found'
      });
    }

    // Get all messages
    const result = await pool.request()
      .input('conversationId', conversationId)
      .query(`
        SELECT 
          message_id,
          conversation_id,
          sender_type,
          sender_id,
          message,
          created_at,
          is_read
        FROM ChatMessages
        WHERE conversation_id = @conversationId
        ORDER BY created_at ASC
      `);

    const messages = result.recordset.map(row => ({
      id: `msg_${row.message_id}`,
      message: row.message,
      sender_type: row.sender_type,
      sender_id: row.sender_id,
      created_at: row.created_at,
      is_read: row.is_read
    }));

    res.json({
      success: true,
      messages: messages
    });

  } catch (error) {
    console.error('❌ Error fetching messages:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch messages',
      message: error.message
    });
  }
});

// Send message from admin to user
router.post('/admin/conversations/:conversationId/messages', authenticateAdmin, async (req, res) => {
  try {
    const conversationId = req.params.conversationId.replace('chat_', '');
    const { message, grievance_id } = req.body;

    if (!message || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Message content is required'
      });
    }

    const pool = dbService.getPool();
    
    // Verify conversation exists
    const convCheck = await pool.request()
      .input('conversationId', conversationId)
      .query(`
        SELECT conversation_id, grievance_id, citizen_id 
        FROM ChatConversations 
        WHERE conversation_id = @conversationId
      `);
    
    if (convCheck.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found'
      });
    }

    // Insert admin message (avoid OUTPUT clause due to triggers)
    await pool.request()
      .input('conversationId', conversationId)
      .input('message', message.trim())
      .query(`
        INSERT INTO ChatMessages (conversation_id, sender_type, sender_id, message, is_read)
        VALUES (@conversationId, 'admin', NULL, @message, 0)
      `);

    // Get the inserted message details
    const result = await pool.request()
      .input('conversationId', conversationId)
      .input('message', message.trim())
      .query(`
        SELECT TOP 1 message_id, created_at, message
        FROM ChatMessages 
        WHERE conversation_id = @conversationId 
          AND sender_type = 'admin' 
          AND message = @message
        ORDER BY created_at DESC
      `);

    const newMessage = result.recordset[0];

    // Mark user messages as read (admin has seen them)
    await pool.request()
      .input('conversationId', conversationId)
      .query(`
        UPDATE ChatMessages 
        SET is_read = 1 
        WHERE conversation_id = @conversationId 
        AND sender_type = 'user' 
        AND is_read = 0
      `);

    res.json({
      success: true,
      message: 'Message sent successfully',
      messageData: {
        id: `msg_${newMessage.message_id}`,
        message: message.trim(),
        sender_type: 'admin',
        created_at: newMessage.created_at,
        is_read: false
      }
    });

  } catch (error) {
    console.error('❌ Error sending message:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to send message',
      message: error.message
    });
  }
});

// Mark conversation as read (admin side)
router.patch('/admin/conversations/:conversationId/read', authenticateAdmin, async (req, res) => {
  try {
    const conversationId = req.params.conversationId.replace('chat_', '');
    const pool = dbService.getPool();
    
    // Mark all user messages in this conversation as read
    await pool.request()
      .input('conversationId', conversationId)
      .query(`
        UPDATE ChatMessages 
        SET is_read = 1 
        WHERE conversation_id = @conversationId 
        AND sender_type = 'user' 
        AND is_read = 0
      `);

    res.json({
      success: true,
      message: 'Conversation marked as read'
    });

  } catch (error) {
    console.error('❌ Error marking conversation as read:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to mark conversation as read',
      message: error.message
    });
  }
});

// ==========================
// USER CHAT ENDPOINTS
// ==========================

// Get or create conversation for a grievance
router.get('/user/conversations/:grievanceId', authenticateUser, async (req, res) => {
  try {
    const { grievanceId } = req.params;
    const citizenId = req.user.citizen_id;
    const pool = dbService.getPool();

    // First, get grievance details to ensure it belongs to this user
    const grievanceResult = await pool.request()
      .input('grievanceId', grievanceId)
      .input('citizenId', citizenId)
      .query(`
        SELECT grievance_id, grievance_number, title, citizen_id
        FROM Grievances 
        WHERE grievance_id = @grievanceId AND citizen_id = @citizenId
      `);

    if (grievanceResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Grievance not found or access denied'
      });
    }

    const grievance = grievanceResult.recordset[0];

    // Check if conversation already exists
    let conversationResult = await pool.request()
      .input('grievanceId', grievanceId)
      .query(`
        SELECT conversation_id, status, created_at
        FROM ChatConversations 
        WHERE grievance_id = @grievanceId
      `);

    let conversationId;
    
    if (conversationResult.recordset.length === 0) {
      // Create new conversation (avoid OUTPUT clause due to triggers)
      await pool.request()
        .input('grievanceId', grievanceId)
        .input('citizenId', citizenId)
        .query(`
          INSERT INTO ChatConversations (grievance_id, citizen_id, status)
          VALUES (@grievanceId, @citizenId, 'active')
        `);
      
      // Get the created conversation ID
      const newConvResult = await pool.request()
        .input('grievanceId', grievanceId)
        .query(`
          SELECT conversation_id FROM ChatConversations 
          WHERE grievance_id = @grievanceId
        `);
      
      conversationId = newConvResult.recordset[0].conversation_id;
    } else {
      conversationId = conversationResult.recordset[0].conversation_id;
    }

    // Get messages
    const messagesResult = await pool.request()
      .input('conversationId', conversationId)
      .query(`
        SELECT 
          message_id,
          sender_type,
          message,
          created_at,
          is_read
        FROM ChatMessages
        WHERE conversation_id = @conversationId
        ORDER BY created_at ASC
      `);

    const messages = messagesResult.recordset.map(row => ({
      id: `msg_${row.message_id}`,
      message: row.message,
      sender_type: row.sender_type,
      created_at: row.created_at,
      is_read: row.is_read
    }));

    res.json({
      success: true,
      conversation: {
        id: `chat_${conversationId}`,
        grievance_id: grievance.grievance_number,
        grievance_title: grievance.title,
        status: conversationResult.recordset[0]?.status || 'active'
      },
      messages: messages
    });

  } catch (error) {
    console.error('❌ Error fetching user conversation:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch conversation',
      message: error.message
    });
  }
});

// Send message from user
router.post('/user/conversations/:grievanceId/messages', authenticateUser, async (req, res) => {
  try {
    const { grievanceId } = req.params;
    const { message } = req.body;
    const citizenId = req.user.citizen_id;

    if (!message || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Message content is required'
      });
    }

    const pool = dbService.getPool();

    // Verify grievance belongs to user
    const grievanceResult = await pool.request()
      .input('grievanceId', grievanceId)
      .input('citizenId', citizenId)
      .query(`
        SELECT grievance_id FROM Grievances 
        WHERE grievance_id = @grievanceId AND citizen_id = @citizenId
      `);

    if (grievanceResult.recordset.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Grievance not found or access denied'
      });
    }

    // Get or create conversation
    let conversationResult = await pool.request()
      .input('grievanceId', grievanceId)
      .query(`
        SELECT conversation_id FROM ChatConversations 
        WHERE grievance_id = @grievanceId
      `);

    let conversationId;
    
    if (conversationResult.recordset.length === 0) {
      // Create conversation (avoid OUTPUT clause due to triggers)
      await pool.request()
        .input('grievanceId', grievanceId)
        .input('citizenId', citizenId)
        .query(`
          INSERT INTO ChatConversations (grievance_id, citizen_id, status)
          VALUES (@grievanceId, @citizenId, 'active')
        `);
      
      // Get the created conversation ID
      const newConvResult = await pool.request()
        .input('grievanceId', grievanceId)
        .query(`
          SELECT conversation_id FROM ChatConversations 
          WHERE grievance_id = @grievanceId
        `);
      
      conversationId = newConvResult.recordset[0].conversation_id;
    } else {
      conversationId = conversationResult.recordset[0].conversation_id;
    }

    // Insert user message (avoid OUTPUT clause due to triggers)
    await pool.request()
      .input('conversationId', conversationId)
      .input('citizenId', citizenId)
      .input('message', message.trim())
      .query(`
        INSERT INTO ChatMessages (conversation_id, sender_type, sender_id, message, is_read)
        VALUES (@conversationId, 'user', @citizenId, @message, 0)
      `);

    // Get the inserted message details
    const result = await pool.request()
      .input('conversationId', conversationId)
      .input('citizenId', citizenId)
      .input('message', message.trim())
      .query(`
        SELECT TOP 1 message_id, created_at
        FROM ChatMessages 
        WHERE conversation_id = @conversationId 
          AND sender_type = 'user' 
          AND sender_id = @citizenId 
          AND message = @message
        ORDER BY created_at DESC
      `);

    const newMessage = result.recordset[0];

    res.json({
      success: true,
      message: 'Message sent successfully',
      messageData: {
        id: `msg_${newMessage.message_id}`,
        message: message.trim(),
        sender_type: 'user',
        created_at: newMessage.created_at,
        is_read: false
      }
    });

  } catch (error) {
    console.error('❌ Error sending user message:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to send message',
      message: error.message
    });
  }
});

module.exports = router;
