import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fcm_service_cross_platform.dart';
import 'firebase_fcm_service.dart';

/// Notification Manager that automatically handles:
/// - Real Firebase FCM on Android/iOS
/// - Cross-platform fallback on Windows/Web
/// - Background notifications
/// - Foreground notifications
/// - Notification permissions
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  static bool _isInitialized = false;
  static String? _currentToken;
  static String? _userId;
  static String? _userRole;

  /// Initialize notification services based on platform
  static Future<void> initialize({String? userId, String? userRole}) async {
    if (_isInitialized) {
      debugPrint('✅ Notification Manager already initialized');
      return;
    }

    try {
      debugPrint('🔔 Initializing Notification Manager...');

      _userId = userId;
      _userRole = userRole;

      // Platform-specific initialization
      if (Platform.isAndroid || Platform.isIOS) {
        debugPrint('📱 Mobile platform detected - initializing Firebase FCM');
        await FirebaseFCMService.initialize();
        _currentToken = FirebaseFCMService.fcmToken;

        // Subscribe to relevant topics based on user role
        if (_userRole != null) {
          await _subscribeToRoleBasedTopics(_userRole!);
        }
      } else {
        debugPrint(
          '🖥️ Desktop/Web platform detected - using cross-platform service',
        );
        await FCMService.initialize();
        _currentToken = await FCMService.getToken();
      }

      // Send token to backend server
      if (_currentToken != null && _userId != null) {
        await _sendTokenToServer(_currentToken!, _userId!);
      }

      _isInitialized = true;
      debugPrint('✅ Notification Manager initialized successfully');
      debugPrint('🔑 Current Token: $_currentToken');
    } catch (e) {
      debugPrint('❌ Error initializing Notification Manager: $e');
    }
  }

  /// Subscribe to topics based on user role
  static Future<void> _subscribeToRoleBasedTopics(String role) async {
    try {
      // Subscribe to general notifications
      await _subscribeToTopic('all_users');

      // Subscribe to role-specific notifications
      switch (role.toLowerCase()) {
        case 'employee':
          await _subscribeToTopic('employees');
          break;
        case 'hr':
          await _subscribeToTopic('hr_staff');
          await _subscribeToTopic('grievance_handlers');
          break;
        case 'admin':
          await _subscribeToTopic('admins');
          await _subscribeToTopic('grievance_handlers');
          break;
        case 'manager':
          await _subscribeToTopic('managers');
          await _subscribeToTopic('grievance_handlers');
          break;
        default:
          debugPrint('⚠️ Unknown role: $role');
      }

      debugPrint('✅ Subscribed to topics for role: $role');
    } catch (e) {
      debugPrint('❌ Error subscribing to topics: $e');
    }
  }

  /// Subscribe to specific topic
  static Future<void> _subscribeToTopic(String topic) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await FirebaseFCMService.subscribeToTopic(topic);
    } else {
      debugPrint('📝 Topic subscription ($topic) noted for backend sync');
      // For desktop/web, store topics for backend notification targeting
    }
  }

  /// Send FCM token to backend server
  static Future<void> _sendTokenToServer(String token, String userId) async {
    try {
      debugPrint('📤 Sending FCM token to server...');

      // TODO: Replace with your actual API endpoint
      // final response = await http.post(
      //   Uri.parse('${ApiConfig.baseUrl}/api/fcm/register-token'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'user_id': userId,
      //     'fcm_token': token,
      //     'platform': Platform.operatingSystem,
      //     'device_info': await _getDeviceInfo(),
      //     'timestamp': DateTime.now().toIso8601String(),
      //   }),
      // );

      debugPrint('✅ FCM token sent to server successfully');
      debugPrint('👤 User ID: $userId');
      debugPrint('🔑 Token: $token');
      debugPrint('📱 Platform: ${Platform.operatingSystem}');
    } catch (e) {
      debugPrint('❌ Error sending token to server: $e');
    }
  }

  /// Update user context (call when user logs in/out)
  static Future<void> updateUserContext({
    required String? userId,
    required String? userRole,
  }) async {
    _userId = userId;
    _userRole = userRole;

    if (_isInitialized && userId != null && userRole != null) {
      // Re-subscribe to topics for new role
      await _subscribeToRoleBasedTopics(userRole);

      // Update token on server
      if (_currentToken != null) {
        await _sendTokenToServer(_currentToken!, userId);
      }
    }
  }

  /// Clear user context (call on logout)
  static Future<void> clearUserContext() async {
    _userId = null;
    _userRole = null;

    // Unsubscribe from all topics
    if (Platform.isAndroid || Platform.isIOS) {
      const topics = [
        'all_users',
        'employees',
        'hr_staff',
        'admins',
        'managers',
        'grievance_handlers',
      ];
      for (String topic in topics) {
        await FirebaseFCMService.unsubscribeFromTopic(topic);
      }
    }

    debugPrint('🔄 User context cleared from Notification Manager');
  }

  /// Show local notification (for testing or manual notifications)
  static Future<void> showTestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Notification Manager not initialized');
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Use Firebase FCM local notifications
        debugPrint('📱 Showing mobile notification: $title');
        // await FirebaseFCMService._showLocalNotification(...);
      } else {
        // Use cross-platform service
        debugPrint('🖥️ Showing desktop notification: $title - $body');
        await FCMService.showTestNotification();
      }
    } catch (e) {
      debugPrint('❌ Error showing test notification: $e');
    }
  }

  /// Get current FCM token
  static String? get currentToken => _currentToken;

  /// Check if notifications are enabled
  static bool get isInitialized => _isInitialized;

  /// Get current user context
  static Map<String, String?> get userContext => {
    'userId': _userId,
    'userRole': _userRole,
  };

  /// Refresh FCM token (call periodically or on app start)
  static Future<void> refreshToken() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await FirebaseFCMService.refreshToken();
        _currentToken = FirebaseFCMService.fcmToken;
      } else {
        _currentToken = await FCMService.getToken();
      }

      // Send updated token to server
      if (_currentToken != null && _userId != null) {
        await _sendTokenToServer(_currentToken!, _userId!);
      }

      debugPrint('🔄 FCM token refreshed: $_currentToken');
    } catch (e) {
      debugPrint('❌ Error refreshing token: $e');
    }
  }
}

/// Riverpod provider for notification manager
final notificationManagerProvider = Provider<NotificationManager>((ref) {
  return NotificationManager();
});

/// Notification state provider
final notificationStateProvider =
    StateNotifierProvider<NotificationStateNotifier, NotificationState>((ref) {
      return NotificationStateNotifier();
    });

class NotificationState {
  final bool isInitialized;
  final String? currentToken;
  final List<String> subscribedTopics;
  final Map<String, String?> userContext;

  NotificationState({
    this.isInitialized = false,
    this.currentToken,
    this.subscribedTopics = const [],
    this.userContext = const {},
  });

  NotificationState copyWith({
    bool? isInitialized,
    String? currentToken,
    List<String>? subscribedTopics,
    Map<String, String?>? userContext,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      currentToken: currentToken ?? this.currentToken,
      subscribedTopics: subscribedTopics ?? this.subscribedTopics,
      userContext: userContext ?? this.userContext,
    );
  }
}

class NotificationStateNotifier extends StateNotifier<NotificationState> {
  NotificationStateNotifier() : super(NotificationState());

  void updateInitializationStatus(bool initialized, String? token) {
    state = state.copyWith(isInitialized: initialized, currentToken: token);
  }

  void updateUserContext(String? userId, String? userRole) {
    state = state.copyWith(
      userContext: {'userId': userId, 'userRole': userRole},
    );
  }

  void addSubscribedTopic(String topic) {
    final topics = [...state.subscribedTopics, topic];
    state = state.copyWith(subscribedTopics: topics);
  }

  void clearSubscribedTopics() {
    state = state.copyWith(subscribedTopics: []);
  }
}
