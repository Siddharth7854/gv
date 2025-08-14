import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Real Firebase FCM Service for Android/iOS
/// Handles background notifications, foreground notifications, and token management
class FirebaseFCMService {
  static final FirebaseFCMService _instance = FirebaseFCMService._internal();
  factory FirebaseFCMService() => _instance;
  FirebaseFCMService._internal();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static String? _fcmToken;

  /// Initialize Firebase FCM service
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔥 Firebase FCM service already initialized');
      return;
    }

    try {
      // Check if platform supports Firebase FCM
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint(
          '⚠️ Firebase FCM not supported on ${Platform.operatingSystem}',
        );
        debugPrint(
          '💡 Use cross_platform_fcm_service for ${Platform.operatingSystem}',
        );
        return;
      }

      debugPrint('🔥 Initializing Firebase FCM service...');

      // Step 1: Firebase is already initialized in main.dart
      debugPrint('✅ Firebase Core already initialized');

      // Step 2: Initialize Firebase Messaging
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Step 3: Request permissions for all platforms
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      
      debugPrint('🔔 Notification permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('❌ Notification permissions denied by user');
        return;
      }

      // Step 4: Initialize local notifications for foreground handling
      await _initializeLocalNotifications();

      // Step 5: Get FCM token - REAL TOKEN FOR CONSOLE TESTING
      _fcmToken = await messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('🔑 REAL FCM TOKEN FOR CONSOLE TESTING:');
        debugPrint('=' * 60);
        debugPrint(_fcmToken!);
        debugPrint('=' * 60);
        debugPrint('✅ Copy this token and use in Firebase Console');
        debugPrint('📍 Firebase Console > Cloud Messaging > Send test message');
        debugPrint('📱 Platform: ${Platform.operatingSystem}');
      } else {
        debugPrint('❌ Failed to get FCM token');
      }

      // Step 6: Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed: ${newToken.substring(0, 50)}...');
        // TODO: Send updated token to your server
      });

      // Step 7: Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Step 8: Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Step 9: Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      _isInitialized = true;
      debugPrint('✅ Firebase FCM Service initialized successfully');
      debugPrint('📲 Ready to receive push notifications');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase FCM: $e');
      debugPrint('💡 Make sure Firebase is properly configured:');
      debugPrint('   - google-services.json in android/app/');
      debugPrint('   - GoogleService-Info.plist in ios/Runner/');
      debugPrint('   - Firebase dependencies in pubspec.yaml');
      debugPrint('   - Internet connection available');
    }
  }

  /// Initialize local notifications for foreground messages
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Handle background messages (static function required)
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Background message: ${message.notification?.title}');
    debugPrint('📝 Message data: ${message.data}');
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message: ${message.notification?.title}');
    debugPrint('📝 Message data: ${message.data}');

    // Show local notification when app is in foreground
    _showLocalNotification(message);
  }

  /// Handle notification tap when app opens from notification
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint(
      '🔔 App opened from notification: ${message.notification?.title}',
    );
    debugPrint('📝 Message data: ${message.data}');
  }

  /// Show local notification for foreground messages (creates dropdown notification)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // Enhanced Android notification settings for better dropdown display
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'fcm_default_channel',
            'FCM Notifications',
            channelDescription: 'Firebase Cloud Messaging notifications for grievance system',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF1976D2),
            enableVibration: true,
            enableLights: true,
            ledColor: const Color(0xFF1976D2),
            showWhen: true,
            when: null,
            usesChronometer: false,
            channelShowBadge: true,
            onlyAlertOnce: false,
            ongoing: false,
            autoCancel: true,
            silent: false,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('notification'),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(
              message.notification?.body ?? 'You have a new notification',
              contentTitle: message.notification?.title ?? 'Grievance Portal',
              summaryText: 'Government Grievance System',
            ),
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        threadIdentifier: 'grievance_notifications',
        subtitle: 'Government Grievance Portal',
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? 'You have a new message from grievance system',
        notificationDetails,
        payload: message.data['grievance_id'] ?? message.data.toString(),
      );

      debugPrint('✅ Dropdown notification shown for FCM message');
    } catch (e) {
      debugPrint('❌ Error showing dropdown notification: $e');
    }
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Subscribe to topic for specific department/role
  static Future<void> subscribeToTopic(String topic) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Firebase FCM not initialized');
      return;
    }

    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Firebase FCM not initialized');
      return;
    }

    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Refresh FCM token
  static Future<void> refreshToken() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Firebase FCM not initialized');
      return;
    }

    try {
      _fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('🔄 FCM Token refreshed: $_fcmToken');
    } catch (e) {
      debugPrint('❌ Error refreshing FCM token: $e');
    }
  }

  /// Get FCM token for console testing
  static Future<String?> getTokenForTesting() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_fcmToken != null) {
        debugPrint('🔥 FCM TOKEN FOR FIREBASE CONSOLE TESTING:');
        debugPrint('=' * 70);
        debugPrint(_fcmToken!);
        debugPrint('=' * 70);
        debugPrint('📋 COPY THIS TOKEN');
        debugPrint('📍 Firebase Console > Cloud Messaging > Send test message');
        debugPrint('📱 Platform: ${Platform.operatingSystem}');
        debugPrint('✅ Paste token in "FCM registration token" field');
        return _fcmToken;
      } else {
        debugPrint('❌ No FCM token available');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Show test notification locally (to test dropdown display)
  static Future<void> showTestNotification() async {
    try {
      if (!_isInitialized) {
        debugPrint('⚠️ Firebase FCM not initialized');
        return;
      }

      // Create a mock RemoteMessage for testing
      final Map<String, dynamic> mockData = {
        'title': 'Test Notification',
        'body': 'This is a test notification from your app',
        'grievance_id': 'test_123',
        'type': 'test',
      };

      // Create mock notification
      final mockMessage = RemoteMessage(
        messageId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        data: mockData,
        notification: RemoteNotification(
          title: 'Test Notification',
          body: 'This is a test notification to check dropdown display',
        ),
      );

      await _showLocalNotification(mockMessage);
      debugPrint('✅ Test dropdown notification sent');
    } catch (e) {
      debugPrint('❌ Error showing test notification: $e');
    }
  }
}
