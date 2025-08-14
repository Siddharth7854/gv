import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMTestWidget extends StatefulWidget {
  const FCMTestWidget({super.key});

  @override
  State<FCMTestWidget> createState() => _FCMTestWidgetState();
}

class _FCMTestWidgetState extends State<FCMTestWidget> {
  String? _fcmToken;
  String _lastNotification = 'No notifications received';
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    try {
      // Request permission
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('FCM Permission: ${settings.authorizationStatus}');

      // Get token
      String? token = await FirebaseMessaging.instance.getToken();
      setState(() {
        _fcmToken = token;
      });
      
      debugPrint('FCM Token: $token');

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings = 
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _localNotifications.initialize(initializationSettings);

      // Create notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'fcm_test_channel',
        'FCM Test Notifications',
        description: 'Channel for FCM testing',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message: ${message.notification?.title}');
        
        setState(() {
          _lastNotification = 
              'Title: ${message.notification?.title}\n'
              'Body: ${message.notification?.body}\n'
              'Time: ${DateTime.now().toString()}';
        });

        _showLocalNotification(message);
      });

      // Listen to background/terminated app messages
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Background message opened: ${message.notification?.title}');
        
        setState(() {
          _lastNotification = 
              'Opened from background:\n'
              'Title: ${message.notification?.title}\n'
              'Body: ${message.notification?.body}\n'
              'Time: ${DateTime.now().toString()}';
        });
      });

    } catch (e) {
      debugPrint('FCM Initialization Error: $e');
      setState(() {
        _lastNotification = 'Error: $e';
      });
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fcm_test_channel',
      'FCM Test Notifications',
      channelDescription: 'Channel for FCM testing',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.notification.hashCode,
      message.notification?.title ?? 'FCM Test',
      message.notification?.body ?? 'Test notification',
      notificationDetails,
    );
  }

  Future<void> _copyTokenToClipboard() async {
    if (_fcmToken != null) {
      // You can implement clipboard copy here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Token copied: ${_fcmToken!.substring(0, 20)}...'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SelectableText(
                        _fcmToken ?? 'Loading token...',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _fcmToken != null ? _copyTokenToClipboard : null,
                      child: const Text('Copy Token'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Notification:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        _lastNotification,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Copy the FCM token above\n'
                      '2. Use Firebase Console to send test notification\n'
                      '3. Or use your server/API to send notification\n'
                      '4. Check for notifications in foreground/background\n'
                      '5. Last notification will appear above',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
