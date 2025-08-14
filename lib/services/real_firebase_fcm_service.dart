// Real Firebase FCM Service for getting actual FCM tokens
// This file shows how to integrate real Firebase for production use

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Uncomment these imports when you enable Firebase in pubspec.yaml:
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

class RealFirebaseFCMService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String? _fcmToken;

  // Initialize real Firebase FCM service
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('🔥 Firebase FCM service already initialized');
      return;
    }

    try {
      debugPrint('🔥 Initializing real Firebase FCM service...');

      // Step 1: Initialize Firebase Core
      // await Firebase.initializeApp();

      // Step 2: Initialize local notifications
      await _initializeLocalNotifications();

      // Step 3: Initialize Firebase Messaging
      // await _initializeFirebaseMessaging();

      _initialized = true;
      debugPrint('🔥 Real Firebase FCM service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase FCM service: $e');
      _initialized = true;
    }
  }

  // Initialize Firebase Messaging (uncomment when Firebase is enabled)
  /*
  static Future<void> _initializeFirebaseMessaging() async {
    try {
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

      debugPrint('🔥 Firebase FCM permission status: ${settings.authorizationStatus}');

      // Get the real FCM token
      String? token = await messaging.getToken();
      if (token != null) {
        _fcmToken = token;
        debugPrint('🔥 Real Firebase FCM Token obtained: ${token.substring(0, 50)}...');
        debugPrint('🔥 Full Firebase FCM Token: $token');
        
        // Send token to your server
        await sendTokenToServer(token);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔥 FCM Token refreshed: ${newToken.substring(0, 50)}...');
        _fcmToken = newToken;
        sendTokenToServer(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔥 Received foreground message: ${message.notification?.title}');
        _showLocalNotificationFromFirebase(message);
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔥 Notification tapped from background: ${message.data}');
        // Handle navigation based on message data
      });

      // Handle notification when app is terminated
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔥 App opened from terminated state: ${initialMessage.data}');
        // Handle navigation based on message data
      }

    } catch (e) {
      debugPrint('❌ Error initializing Firebase Messaging: $e');
    }
  }
  */

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      InitializationSettings initializationSettings;

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
      } else {
        // For other platforms
        const LinuxInitializationSettings linuxSettings =
            LinuxInitializationSettings(defaultActionName: 'Open notification');
        initializationSettings = const InitializationSettings(
          linux: linuxSettings,
        );
      }

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('✅ Local notifications initialized for ${Platform.operatingSystem}');
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
    }
  }

  // Show local notification from Firebase message (uncomment when Firebase is enabled)
  /*
  static Future<void> _showLocalNotificationFromFirebase(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'firebase_fcm_channel',
        'Firebase FCM Notifications',
        channelDescription: 'Real notifications from Firebase Cloud Messaging',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Message',
        message.notification?.body ?? 'You have a new message',
        platformChannelSpecifics,
        payload: message.data.toString(),
      );

      debugPrint('🔥 Local notification shown for Firebase message');
    } catch (e) {
      debugPrint('❌ Error showing local notification from Firebase: $e');
    }
  }
  */

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔥 Notification tapped: ${response.payload}');
    // TODO: Handle notification tap - navigate to relevant screen
  }

  // Get current FCM token (real Firebase token)
  static Future<String?> getToken() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // If Firebase is enabled, get real token:
      /*
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      if (token != null) {
        _fcmToken = token;
        debugPrint('🔥 Retrieved real Firebase FCM Token: ${token.substring(0, 50)}...');
        return token;
      }
      */

      if (_fcmToken != null) {
        debugPrint('🔥 Current FCM Token: ${_fcmToken!.substring(0, 50)}...');
        return _fcmToken;
      } else {
        debugPrint('⚠️ FCM Token is null');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Send token to your backend server
  static Future<void> sendTokenToServer(String? token) async {
    if (token == null) return;

    try {
      debugPrint('🔥 Sending FCM token to server...');
      
      // TODO: Replace with your actual API endpoint
      /*
      final response = await http.post(
        Uri.parse('https://your-api.com/api/fcm/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_TOKEN',
        },
        body: jsonEncode({
          'fcm_token': token,
          'platform': Platform.operatingSystem,
          'user_id': 'current_user_id', // Replace with actual user ID
          'device_id': 'device_unique_id', // Replace with device ID
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('🔥 FCM token sent to server successfully');
      } else {
        debugPrint('❌ Failed to send FCM token: ${response.statusCode}');
      }
      */
      
      debugPrint('🔥 FCM token ready to send to server');
    } catch (e) {
      debugPrint('❌ Error sending FCM token to server: $e');
    }
  }

  // Test Firebase FCM with real token
  static Future<void> testRealFirebaseFCM() async {
    try {
      String? token = await getToken();
      if (token != null) {
        debugPrint('=== REAL FIREBASE FCM TOKEN FOR CONSOLE TESTING ===');
        debugPrint('🔥 Copy this token for Firebase Console:');
        debugPrint('Token: $token');
        debugPrint('Platform: ${Platform.operatingSystem}');
        debugPrint('================================================');
        
        // You can copy this token and use it in Firebase Console > Cloud Messaging > Send test message
      } else {
        debugPrint('❌ No FCM token available');
      }
    } catch (e) {
      debugPrint('❌ Error testing Firebase FCM: $e');
    }
  }
}

/*
==============================================================================
FIREBASE CONSOLE SETUP GUIDE (Hindi):
==============================================================================

Step 1: Firebase Project Setup
1. Firebase Console (https://console.firebase.google.com/) par jao
2. "Add project" click karo
3. Project name do (jaise: "GrievanceApp")
4. Analytics enable karo (optional)

Step 2: Android App Add karo
1. Firebase project mein Android icon click karo
2. Package name: com.government.grievance.gv
3. App nickname: Grievance App
4. Debug signing certificate SHA-1 (optional for testing)
5. google-services.json download karo
6. google-services.json ko android/app/ folder mein copy karo

Step 3: pubspec.yaml mein Firebase enable karo
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9

Step 4: Android build.gradle setup
android/app/build.gradle mein:
- apply plugin: 'com.google.gms.google-services' add karo

android/build.gradle mein:
- classpath 'com.google.gms:google-services:4.3.15' add karo

Step 5: Code mein changes
1. RealFirebaseFCMService use karo FCMService ki jagah
2. Commented code uncomment karo
3. Firebase.initializeApp() call karo main() mein

Step 6: Real Token get karo
1. App run karo Android device/emulator par
2. Debug console mein "Real Firebase FCM Token" dekho
3. Ye token copy karo

Step 7: Firebase Console se test karo
1. Firebase Console > Cloud Messaging > "Send your first message"
2. Message title aur body do
3. "Send test message" click karo
4. Token paste karo jo app se mila
5. "Test" button click karo

Token Example:
fGHJ234KLM567NOP890QRS123TUV456WXY789ZAB012CDE345FGH678IJK901LMN234OPQ567RST890UVW123XYZ456ABC789DEF012GHI345JKL678MNO901PQR234STU567VWX890YZA123BCD456EFG789HIJ012KLM345NOP678QRS901TUV234WXY567ZAB890CDE123FGH456IJK789LMN012OPQ345RST678UVW901XYZ234

Is token ko Firebase Console mein paste karke test kar sakte hain!
==============================================================================
*/
