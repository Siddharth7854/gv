const express = require('express');
// Use app.get('dbService') instead of direct import
// const { sql, poolPromise } = require('../config/database');
const auth = require('../middleware/auth');
const admin = require('firebase-admin');

const router = express.Router();

// Initialize Firebase Admin SDK (Add this to your main server.js or config)
// You'll need to add your Firebase service account key
/*
const serviceAccount = require('./path/to/your/firebase-adminsdk-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
*/

// Update FCM Token
router.post('/fcm-token', auth, async (req, res) => {
  try {
    const { fcm_token, platform } = req.body;
    const userId = req.user.citizen_id;

    console.log(`📱 Updating FCM token for user ${userId}: ${fcm_token?.substring(0, 20)}...`);

    const pool = await poolPromise;
    
    // Check if token already exists for this user
    const existingToken = await pool.request()
      .input('UserId', sql.Int, userId)
      .query(`
        SELECT fcm_token_id, fcm_token 
        FROM FCMTokens 
        WHERE user_id = @UserId AND is_active = 1
      `);

    if (existingToken.recordset.length > 0) {
      // Update existing token
      await pool.request()
        .input('UserId', sql.Int, userId)
        .input('FCMToken', sql.NVarChar(500), fcm_token)
        .input('Platform', sql.NVarChar(50), platform || 'flutter')
        .query(`
          UPDATE FCMTokens 
          SET fcm_token = @FCMToken, 
              platform = @Platform, 
              updated_at = GETDATE()
          WHERE user_id = @UserId AND is_active = 1
        `);
      
      console.log(`✅ FCM token updated for user ${userId}`);
    } else {
      // Insert new token
      await pool.request()
        .input('UserId', sql.Int, userId)
        .input('FCMToken', sql.NVarChar(500), fcm_token)
        .input('Platform', sql.NVarChar(50), platform || 'flutter')
        .query(`
          INSERT INTO FCMTokens (user_id, fcm_token, platform, created_at, updated_at, is_active)
          VALUES (@UserId, @FCMToken, @Platform, GETDATE(), GETDATE(), 1)
        `);
      
      console.log(`✅ New FCM token created for user ${userId}`);
    }

    res.json({
      success: true,
      message: 'FCM token updated successfully'
    });

  } catch (error) {
    console.error('❌ Error updating FCM token:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Remove FCM Token
router.delete('/fcm-token', auth, async (req, res) => {
  try {
    const { fcm_token } = req.body;
    const userId = req.user.citizen_id;

    console.log(`🗑️ Removing FCM token for user ${userId}`);

    const pool = await poolPromise;
    
    await pool.request()
      .input('UserId', sql.Int, userId)
      .input('FCMToken', sql.NVarChar(500), fcm_token)
      .query(`
        UPDATE FCMTokens 
        SET is_active = 0, updated_at = GETDATE()
        WHERE user_id = @UserId AND fcm_token = @FCMToken
      `);

    console.log(`✅ FCM token removed for user ${userId}`);

    res.json({
      success: true,
      message: 'FCM token removed successfully'
    });

  } catch (error) {
    console.error('❌ Error removing FCM token:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Update Notification Preferences
router.put('/notification-preferences', auth, async (req, res) => {
  try {
    const { preferences } = req.body;
    const userId = req.user.citizen_id;

    console.log(`⚙️ Updating notification preferences for user ${userId}:`, preferences);

    const pool = await poolPromise;
    
    // Check if preferences already exist
    const existingPrefs = await pool.request()
      .input('UserId', sql.Int, userId)
      .query(`
        SELECT preference_id 
        FROM NotificationPreferences 
        WHERE user_id = @UserId
      `);

    const preferencesJson = JSON.stringify(preferences);

    if (existingPrefs.recordset.length > 0) {
      // Update existing preferences
      await pool.request()
        .input('UserId', sql.Int, userId)
        .input('Preferences', sql.NVarChar(sql.MAX), preferencesJson)
        .query(`
          UPDATE NotificationPreferences 
          SET preferences = @Preferences, updated_at = GETDATE()
          WHERE user_id = @UserId
        `);
    } else {
      // Insert new preferences
      await pool.request()
        .input('UserId', sql.Int, userId)
        .input('Preferences', sql.NVarChar(sql.MAX), preferencesJson)
        .query(`
          INSERT INTO NotificationPreferences (user_id, preferences, created_at, updated_at)
          VALUES (@UserId, @Preferences, GETDATE(), GETDATE())
        `);
    }

    console.log(`✅ Notification preferences updated for user ${userId}`);

    res.json({
      success: true,
      message: 'Notification preferences updated successfully'
    });

  } catch (error) {
    console.error('❌ Error updating notification preferences:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Get Notification Preferences
router.get('/notification-preferences', auth, async (req, res) => {
  try {
    const userId = req.user.citizen_id;

    console.log(`📖 Getting notification preferences for user ${userId}`);

    const pool = await poolPromise;
    
    const result = await pool.request()
      .input('UserId', sql.Int, userId)
      .query(`
        SELECT preferences 
        FROM NotificationPreferences 
        WHERE user_id = @UserId
      `);

    let preferences = {
      grievance_updates: true,
      chat_messages: true,
      admin_alerts: true,
      reminders: true,
      sound: true,
      vibration: true,
    };

    if (result.recordset.length > 0 && result.recordset[0].preferences) {
      try {
        preferences = JSON.parse(result.recordset[0].preferences);
      } catch (parseError) {
        console.warn('⚠️ Failed to parse preferences, using defaults');
      }
    }

    console.log(`✅ Retrieved notification preferences for user ${userId}`);

    res.json({
      success: true,
      data: preferences
    });

  } catch (error) {
    console.error('❌ Error getting notification preferences:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Send Push Notification (Utility function)
async function sendPushNotification(userId, notification) {
  try {
    console.log(`🔔 Sending push notification to user ${userId}:`, notification);

    const pool = await poolPromise;
    
    // Get active FCM tokens for user
    const tokensResult = await pool.request()
      .input('UserId', sql.Int, userId)
      .query(`
        SELECT fcm_token 
        FROM FCMTokens 
        WHERE user_id = @UserId AND is_active = 1
      `);

    if (tokensResult.recordset.length === 0) {
      console.log(`⚠️ No active FCM tokens found for user ${userId}`);
      return { success: false, error: 'No active tokens found' };
    }

    // Get user notification preferences
    const prefsResult = await pool.request()
      .input('UserId', sql.Int, userId)
      .query(`
        SELECT preferences 
        FROM NotificationPreferences 
        WHERE user_id = @UserId
      `);

    let userPreferences = {
      grievance_updates: true,
      chat_messages: true,
      admin_alerts: true,
      reminders: true,
      sound: true,
      vibration: true,
    };

    if (prefsResult.recordset.length > 0 && prefsResult.recordset[0].preferences) {
      try {
        userPreferences = JSON.parse(prefsResult.recordset[0].preferences);
      } catch (parseError) {
        console.warn('⚠️ Failed to parse user preferences, using defaults');
      }
    }

    // Check if user has enabled this notification type
    const notificationType = notification.data?.type || 'general';
    const preferenceKey = `${notificationType.replace('_', '_')}`;
    
    if (userPreferences[preferenceKey] === false) {
      console.log(`🔇 User ${userId} has disabled ${notificationType} notifications`);
      return { success: true, message: 'User has disabled this notification type' };
    }

    // Prepare FCM message
    const tokens = tokensResult.recordset.map(row => row.fcm_token);
    
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
      android: {
        notification: {
          channelId: getChannelId(notificationType),
          priority: 'high',
          sound: userPreferences.sound ? 'default' : undefined,
          vibrationPattern: userPreferences.vibration ? [1000, 500, 1000] : undefined,
        }
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notification.title,
              body: notification.body,
            },
            sound: userPreferences.sound ? 'default' : undefined,
          }
        }
      },
      tokens: tokens,
    };

    // Send notification using Firebase Admin SDK
    const response = await admin.messaging().sendMulticast(message);
    
    console.log(`✅ Push notification sent to ${response.successCount}/${tokens.length} tokens`);
    
    if (response.failureCount > 0) {
      console.warn(`⚠️ Failed to send to ${response.failureCount} tokens:`, response.responses);
      
      // Remove invalid tokens
      for (let i = 0; i < response.responses.length; i++) {
        const resp = response.responses[i];
        if (!resp.success && (
          resp.error?.code === 'messaging/invalid-registration-token' ||
          resp.error?.code === 'messaging/registration-token-not-registered'
        )) {
          const invalidToken = tokens[i];
          console.log(`🗑️ Removing invalid token: ${invalidToken.substring(0, 20)}...`);
          
          await pool.request()
            .input('FCMToken', sql.NVarChar(500), invalidToken)
            .query(`
              UPDATE FCMTokens 
              SET is_active = 0, updated_at = GETDATE()
              WHERE fcm_token = @FCMToken
            `);
        }
      }
    }

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };

  } catch (error) {
    console.error('❌ Error sending push notification:', error);
    return { success: false, error: error.message };
  }
}

// Helper function to get notification channel ID
function getChannelId(notificationType) {
  switch (notificationType) {
    case 'grievance_status':
      return 'grievance_notifications';
    case 'admin_alert':
      return 'admin_notifications';
    case 'chat_message':
      return 'chat_notifications';
    default:
      return 'grievance_notifications';
  }
}

/**
 * Send test notification to all users (for development)
 * POST /api/notifications/test
 */
router.post('/test', auth, async (req, res) => {
  try {
    const { 
      title = '🔔 Test Notification',
      body = 'This is a test notification from the Grievance Management System',
    } = req.body;

    console.log('🔔 Sending test notification to all users...');

    const pool = await poolPromise;
    
    // Get all active FCM tokens
    const result = await pool.request().query(`
      SELECT u.citizen_id, u.full_name, f.fcm_token, f.platform
      FROM citizens u
      INNER JOIN FCMTokens f ON u.citizen_id = f.user_id
      WHERE f.is_active = 1 AND f.fcm_token IS NOT NULL
    `);

    const users = result.recordset;
    console.log(`📋 Found ${users.length} users with FCM tokens`);

    if (users.length === 0) {
      return res.json({
        success: false,
        message: 'No users found with active FCM tokens',
        sent_count: 0
      });
    }

    // Send notifications to all users
    const results = [];
    let successCount = 0;

    for (const user of users) {
      try {
        const notificationResult = await sendPushNotification(
          user.fcm_token,
          title,
          body,
          {
            type: 'test_notification',
            test_mode: 'true',
            timestamp: new Date().toISOString()
          }
        );

        console.log(`📤 Test notification sent to ${user.full_name} (${user.platform})`);
        
        results.push({
          user_id: user.citizen_id,
          user_name: user.full_name,
          platform: user.platform,
          status: 'success',
          message_id: notificationResult?.messageId || 'simulated'
        });
        
        successCount++;
      } catch (error) {
        console.error(`❌ Failed to send to ${user.full_name}:`, error.message);
        results.push({
          user_id: user.citizen_id,
          user_name: user.full_name,
          platform: user.platform,
          status: 'failed',
          error: error.message
        });
      }
    }

    res.json({
      success: true,
      message: `Test notification sent to ${successCount}/${users.length} users`,
      sent_count: successCount,
      total_users: users.length,
      results: results,
      notification: { title, body },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error sending test notification:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to send test notification',
      details: error.message
    });
  }
});

/**
 * Send notification to specific users by role
 * POST /api/notifications/send-by-role
 */
router.post('/send-by-role', auth, async (req, res) => {
  try {
    const { 
      title, 
      body, 
      roles,  // Array of roles: ['citizen', 'admin', 'hr']
      data = {}
    } = req.body;

    if (!title || !body || !roles || roles.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Title, body, and roles are required'
      });
    }

    console.log(`🔔 Sending notification to roles: ${roles.join(', ')}`);

    const pool = await poolPromise;
    
    // Get FCM tokens for users with specified roles
    const placeholders = roles.map(() => '?').join(',');
    const query = `
      SELECT u.citizen_id, u.full_name, u.role, f.fcm_token, f.platform
      FROM citizens u
      INNER JOIN FCMTokens f ON u.citizen_id = f.user_id
      WHERE f.is_active = 1 AND f.fcm_token IS NOT NULL
      AND u.role IN (${placeholders})
    `;

    const result = await pool.request().query(query, roles);
    const users = result.recordset;

    console.log(`📋 Found ${users.length} users with specified roles`);

    if (users.length === 0) {
      return res.json({
        success: false,
        message: 'No users found with specified roles',
        sent_count: 0,
        roles: roles
      });
    }

    // Send notifications
    const results = [];
    let successCount = 0;

    for (const user of users) {
      try {
        await sendPushNotification(
          user.fcm_token,
          title,
          body,
          {
            ...data,
            recipient_role: user.role,
            timestamp: new Date().toISOString()
          }
        );

        console.log(`📤 Notification sent to ${user.full_name} (${user.role})`);
        results.push({
          user_id: user.citizen_id,
          user_name: user.full_name,
          role: user.role,
          platform: user.platform,
          status: 'success'
        });
        
        successCount++;
      } catch (error) {
        console.error(`❌ Failed to send to ${user.full_name}:`, error.message);
        results.push({
          user_id: user.citizen_id,
          user_name: user.full_name,
          role: user.role,
          platform: user.platform,
          status: 'failed',
          error: error.message
        });
      }
    }

    res.json({
      success: true,
      message: `Notification sent to ${successCount}/${users.length} users`,
      sent_count: successCount,
      total_users: users.length,
      target_roles: roles,
      results: results,
      notification: { title, body },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error sending role-based notification:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to send role-based notification',
      details: error.message
    });
  }
});

// Export the sendPushNotification function for use in other modules
module.exports = router;
module.exports.sendPushNotification = sendPushNotification;
