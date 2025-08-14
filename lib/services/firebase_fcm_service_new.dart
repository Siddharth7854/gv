import 'dart:io';
import 'package:flutter/foundation.dart';
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

      // Step 1: Firebase is already initialized in main.dart
      debugPrint('✅ Firebase Core already initialized');

      // Step 2: Initialize Firebase Messaging
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Step 3: Request permissions for iOS
      if (Platform.isIOS) {
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        debugPrint(
          '🍎 iOS notification permission: ${settings.authorizationStatus}',
        );
      }

      // Step 4: Initialize local notifications for foreground handling
      await _initializeLocalNotifications();

      // Step 5: Get FCM token
      _fcmToken = await messaging.getToken();
      debugPrint('🔑 FCM Token: $_fcmToken');

      // Step 6: Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Step 7: Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Step 8: Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      _isInitialized = true;
      debugPrint('✅ Firebase FCM Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase FCM: $e');
      debugPrint('💡 Make sure Firebase is properly configured:');
      debugPrint('   - google-services.json in android/app/');
      debugPrint('   - GoogleService-Info.plist in ios/Runner/');
      debugPrint('   - Firebase dependencies in pubspec.yaml');
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

  /// Show local notification for foreground messages
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default Notifications',
          channelDescription: 'Default notification channel',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
      payload: message.data['grievance_id'],
    );
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
}
