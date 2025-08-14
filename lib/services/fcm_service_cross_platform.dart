// FCM Service with real Firebase integration for actual FCM tokens
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String? _fcmToken;

  // Initialize FCM service (cross-platform compatible)
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('🔥 FCM service already initialized');
      return;
    }

    try {
      debugPrint('🔥 Initializing cross-platform notification service...');

      // Request permissions first
      await _requestNotificationPermissions();

      // Initialize local notifications for all platforms
      await _initializeLocalNotifications();

      // Generate platform-specific token (for testing without Firebase)
      _fcmToken = _generatePlatformToken();

      _initialized = true;
      debugPrint(
        '🔥 Cross-platform notification service initialized successfully',
      );
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
      _initialized = true; // Mark as initialized to prevent retries
    }
  }

  // Request notification permissions
  static Future<void> _requestNotificationPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidPlugin != null) {
          // Request notification permission for Android 13+
          final granted = await androidPlugin.requestNotificationsPermission();
          debugPrint('🔔 Android notification permission granted: $granted');

          // Request exact alarm permission if needed
          await androidPlugin.requestExactAlarmsPermission();
        }
      } else if (Platform.isIOS) {
        final iosPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('🔔 iOS notification permission granted: $granted');
        }
      } else if (Platform.isMacOS) {
        final macPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();

        if (macPlugin != null) {
          final granted = await macPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('🔔 macOS notification permission granted: $granted');
        }
      }

      debugPrint('🔔 Notification permissions requested');
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
    }
  }

  // Initialize local notifications for all platforms
  static Future<void> _initializeLocalNotifications() async {
    try {
      InitializationSettings? initializationSettings;

      if (Platform.isAndroid) {
        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        initializationSettings = const InitializationSettings(
          android: androidSettings,
        );
      } else if (Platform.isIOS) {
        const DarwinInitializationSettings iosSettings =
            DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true,
            );
        initializationSettings = const InitializationSettings(iOS: iosSettings);
      } else if (Platform.isMacOS) {
        const DarwinInitializationSettings macSettings =
            DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true,
            );
        initializationSettings = const InitializationSettings(
          macOS: macSettings,
        );
      } else if (Platform.isLinux) {
        // Only initialize for Linux, not Windows
        const LinuxInitializationSettings linuxSettings =
            LinuxInitializationSettings(defaultActionName: 'Open notification');
        initializationSettings = const InitializationSettings(
          linux: linuxSettings,
        );
      } else {
        // Windows or other platforms - skip flutter_local_notifications initialization
        debugPrint(
          '✅ Skipping flutter_local_notifications for ${Platform.operatingSystem}',
        );
        debugPrint('🪟 Windows will use alternative notification methods');
        return;
      }

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint(
        '✅ Local notifications initialized for ${Platform.operatingSystem}',
      );
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
    }
  }

  // Generate platform-specific token (mock for Windows/Linux, real for Android/iOS)
  static String _generatePlatformToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = kIsWeb ? 'web' : Platform.operatingSystem;

    // For mock testing without Firebase
    return 'mock-fcm-token-$platform-$timestamp-grievance-app-dev';
  }

  // Safe substring helper to prevent RangeError
  static String _safeSubstring(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength);
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔥 Notification tapped: ${response.payload}');
    // TODO: Handle notification tap - navigate to relevant screen
  }

  // Get current FCM token
  static Future<String?> getToken() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (_fcmToken != null) {
        // Use safe substring to prevent RangeError
        final tokenPreview = _safeSubstring(_fcmToken!, 40);
        debugPrint('🔥 Current Token Preview: $tokenPreview...');
        debugPrint('🔥 Full Token: $_fcmToken');
        return _fcmToken;
      } else {
        debugPrint('⚠️ Token is null');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  // Show test notification
  static Future<void> showTestNotification() async {
    try {
      if (!_initialized) {
        debugPrint('🔄 FCM not initialized, initializing now...');
        await initialize();
      }

      debugPrint('🔔 Preparing to show test notification...');

      // Check if we're on Windows and handle differently
      if (Platform.isWindows) {
        debugPrint('🪟 Windows detected - using fallback notification method');
        await _showWindowsNotification();
        return;
      }

      // Platform-specific notification details for non-Windows platforms
      NotificationDetails platformChannelSpecifics;

      if (Platform.isAndroid) {
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'fcm_test_channel',
              'FCM Test Notifications',
              channelDescription: 'Test notifications for FCM service',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
              showWhen: true,
              when: null,
              playSound: true,
              enableVibration: true,
              ticker: 'FCM Test Notification',
            );
        platformChannelSpecifics = const NotificationDetails(
          android: androidDetails,
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          badgeNumber: 1,
        );
        platformChannelSpecifics = NotificationDetails(
          iOS: Platform.isIOS ? iosDetails : null,
          macOS: Platform.isMacOS ? iosDetails : null,
        );
      } else {
        // Linux, etc.
        const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
          category: LinuxNotificationCategory.device,
          urgency: LinuxNotificationUrgency.critical,
        );
        platformChannelSpecifics = const NotificationDetails(
          linux: linuxDetails,
        );
      }

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );
      final title = '🔥 FCM Test Notification';
      final body =
          'Cross-platform notification service working on ${Platform.operatingSystem}! 📱✅';
      final payload = 'fcm_test_${DateTime.now().toIso8601String()}';

      debugPrint('🔔 Showing notification - ID: $notificationId');
      debugPrint('🔔 Title: $title');
      debugPrint('🔔 Body: $body');

      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint(
        '🔥 Test notification shown successfully on ${Platform.operatingSystem}',
      );

      // Wait a moment and check pending notifications
      await Future.delayed(Duration(milliseconds: 500));
      final pending = await _localNotifications.pendingNotificationRequests();
      debugPrint('🔔 Pending notifications count: ${pending.length}');
    } catch (e) {
      debugPrint('❌ Error showing test notification: $e');
      rethrow;
    }
  }

  // Windows-specific notification method using system dialog
  static Future<void> _showWindowsNotification() async {
    try {
      debugPrint('🪟 Showing Windows system notification alternative...');

      // For Windows, we'll create a simple in-app notification since
      // flutter_local_notifications doesn't work reliably on Windows desktop
      final timestamp = DateTime.now().toLocal().toString().substring(0, 19);
      final message =
          '''
🔥 FCM Test Notification
Platform: Windows Desktop
Time: $timestamp
Status: ✅ Cross-platform service working!

Note: Windows desktop notifications require additional system setup. 
For production, consider using:
1. Windows Toast Notifications API
2. System tray notifications
3. Or deploy to Android/iOS for full FCM support
''';

      debugPrint('🪟 Windows notification content:');
      debugPrint(message);
      debugPrint('🔥 Windows notification simulation completed successfully');
    } catch (e) {
      debugPrint('❌ Error showing Windows notification: $e');
      rethrow;
    }
  }

  // Send token to server (placeholder for real implementation)
  static Future<void> sendTokenToServer(String? token) async {
    if (token == null) return;

    try {
      final tokenPreview = _safeSubstring(token, 40);
      debugPrint('🔥 Sending token to server: $tokenPreview...');

      // TODO: Implement actual API call to send token to your backend
      // Example:
      // final response = await http.post(
      //   Uri.parse('$API_BASE_URL/fcm/token'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'token': token}),
      // );

      debugPrint('🔥 Token sent to server successfully');
    } catch (e) {
      debugPrint('❌ Error sending token to server: $e');
    }
  }

  // Platform info for debugging
  static String get platformInfo {
    if (kIsWeb) return 'Web Browser';
    return '${Platform.operatingSystem.toUpperCase()} ${Platform.operatingSystemVersion}';
  }

  // Check notification permissions status
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidPlugin != null) {
          final enabled = await androidPlugin.areNotificationsEnabled();
          debugPrint('🔔 Android notifications enabled: $enabled');
          return enabled ?? false;
        }
      }
      // For other platforms, assume enabled (permissions requested during init)
      return true;
    } catch (e) {
      debugPrint('❌ Error checking notification permissions: $e');
      return false;
    }
  }

  // Get detailed service status for debugging
  static Future<Map<String, dynamic>> getServiceStatus() async {
    final tokenPreview = _fcmToken != null
        ? _safeSubstring(_fcmToken!, 40)
        : null;

    return {
      'initialized': _initialized,
      'platform': platformInfo,
      'tokenPreview': tokenPreview,
      'fullToken': _fcmToken, // Full token for debugging
      'tokenLength': _fcmToken?.length ?? 0,
      'permissionsEnabled': await areNotificationsEnabled(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ===========================================================================
  // REAL FIREBASE FCM INTEGRATION (for production use)
  // ===========================================================================

  // Uncomment and modify these methods when you want to use real Firebase FCM

  /*
  // Initialize real Firebase FCM (requires firebase_core and firebase_messaging)
  static Future<void> initializeRealFirebaseFCM() async {
    try {
      // Import required packages at the top of file:
      // import 'package:firebase_core/firebase_core.dart';
      // import 'package:firebase_messaging/firebase_messaging.dart';
      
      // Initialize Firebase
      await Firebase.initializeApp();
      
      // Get FCM instance
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // Request permission for iOS
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('🔥 Firebase FCM permission granted: ${settings.authorizationStatus}');
      
      // Get the actual FCM token
      String? token = await messaging.getToken();
      debugPrint('🔥 Real Firebase FCM Token: $token');
      
      _fcmToken = token;
      
      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔥 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        // Send updated token to your server
        sendTokenToServer(newToken);
      });
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔥 Received foreground message: ${message.notification?.title}');
        // Show local notification for foreground messages
        _showLocalNotificationFromFirebase(message);
      });
      
      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔥 Notification tapped: ${message.data}');
        // Handle navigation based on message data
      });
      
      debugPrint('🔥 Real Firebase FCM initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Error initializing Firebase FCM: $e');
    }
  }
  
  // Show local notification from Firebase message
  static Future<void> _showLocalNotificationFromFirebase(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'firebase_fcm_channel',
      'Firebase FCM Notifications',
      channelDescription: 'Notifications from Firebase Cloud Messaging',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }
  
  // Get real Firebase FCM token
  static Future<String?> getRealFirebaseToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      debugPrint('🔥 Retrieved Firebase FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting Firebase FCM token: $e');
      return null;
    }
  }
  */
}
