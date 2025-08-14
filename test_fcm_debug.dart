import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'lib/firebase_options.dart';

/// FCM Debug Test App
/// यह app आपकी FCM setup को test करने के लिए है
/// 
/// Run command: flutter run test_fcm_debug.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Initialize
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    return;
  }

  runApp(const FCMDebugApp());
}

class FCMDebugApp extends StatelessWidget {
  const FCMDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Debug Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FCMDebugScreen(),
    );
  }
}

class FCMDebugScreen extends StatefulWidget {
  const FCMDebugScreen({super.key});

  @override
  State<FCMDebugScreen> createState() => _FCMDebugScreenState();
}

class _FCMDebugScreenState extends State<FCMDebugScreen> {
  String? _fcmToken;
  String _statusLog = '';
  bool _isInitialized = false;
  
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  void _log(String message) {
    setState(() {
      _statusLog += '${DateTime.now().toString().substring(11, 19)} - $message\n';
    });
    print(message);
  }

  Future<void> _initializeFCM() async {
    _log('🔄 Starting FCM initialization...');

    try {
      // Check platform
      if (!Platform.isAndroid && !Platform.isIOS) {
        _log('❌ Platform not supported: ${Platform.operatingSystem}');
        return;
      }

      _log('✅ Platform supported: ${Platform.operatingSystem}');

      // Initialize local notifications
      await _initializeLocalNotifications();
      _log('✅ Local notifications initialized');

      // Initialize Firebase Messaging
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permissions
      _log('🔄 Requesting notification permissions...');
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _log('🔔 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log('❌ User denied notification permissions');
        return;
      }

      // Get FCM token
      _log('🔄 Getting FCM token...');
      _fcmToken = await messaging.getToken();
      
      if (_fcmToken != null) {
        _log('✅ FCM Token received!');
        _log('🔑 Token: ${_fcmToken!.substring(0, 50)}...');
        setState(() {});
      } else {
        _log('❌ Failed to get FCM token');
        return;
      }

      // Setup message handlers
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _log('📱 Foreground message received: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _log('🔔 Notification tapped: ${message.notification?.title}');
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      _isInitialized = true;
      _log('✅ FCM initialization completed successfully!');
      _log('🎯 Ready for testing with Firebase Console');

    } catch (e) {
      _log('❌ FCM initialization error: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidSettings, 
          iOS: iosSettings,
        );

    await _localNotifications.initialize(initializationSettings);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fcm_default_channel',
      'FCM Notifications',
      channelDescription: 'Firebase Cloud Messaging notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'Test Notification',
      message.notification?.body ?? 'Test notification body',
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Debug Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _isInitialized ? Colors.green.shade50 : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FCM Status: ${_isInitialized ? "Ready ✅" : "Initializing... 🔄"}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Platform: ${Platform.operatingSystem}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FCM Token Card
            if (_fcmToken != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FCM Token 🔑',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _fcmToken!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Copy to clipboard
                          // Clipboard.setData(ClipboardData(text: _fcmToken!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Token copied to clipboard!')),
                          );
                        },
                        child: const Text('Copy Token'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Instructions Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Instructions 📋',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Copy the FCM Token above'),
                    const Text('2. Go to Firebase Console'),
                    const Text('3. Cloud Messaging > Send test message'),
                    const Text('4. Paste the token'),
                    const Text('5. Send notification'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '⚠️ Make sure app is in background when testing!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status Log
            const Text(
              'Debug Log 📝',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _statusLog.isEmpty ? 'No logs yet...' : _statusLog,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('🔔 Background message: ${message.notification?.title}');
}
