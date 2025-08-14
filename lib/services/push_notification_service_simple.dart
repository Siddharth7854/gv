// Simple Mock Push Notification Service for all platforms
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static bool _initialized = false;
  static String? _mockToken;

  // Initialize FCM service
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('🔔 Push notification service already initialized');
      return;
    }

    try {
      debugPrint('🔔 Initializing mock push notification service...');

      // Generate a mock token
      _mockToken = _generateMockToken();

      _initialized = true;
      debugPrint('✅ Mock push notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing push notification service: $e');
      _initialized = true; // Mark as initialized even if failed
    }
  }

  // Generate a realistic mock FCM token
  static String _generateMockToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = kIsWeb ? 'web' : 'mobile';
    return 'mock-fcm-token-$platform-$timestamp-for-development-testing-only';
  }

  // Get FCM token
  static Future<String?> getToken() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (_mockToken != null) {
        debugPrint('� Mock FCM Token: ${_mockToken!.substring(0, 50)}...');
        return _mockToken;
      } else {
        debugPrint('⚠️ Mock FCM Token is null');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Clear notifications (placeholder)
  static Future<void> clearAllNotifications() async {
    debugPrint('🧹 Clear notifications called (mock implementation)');
  }

  // Schedule notification (placeholder)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    debugPrint('⏰ Schedule notification (mock): $title at $scheduledTime');
  }
}
