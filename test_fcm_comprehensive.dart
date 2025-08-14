import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'lib/firebase_options.dart';

/// FCM Debug Test Tool
/// Tests FCM token generation and notification handling
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting FCM Debug Test...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Initialize Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // Request permissions (for iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('📱 Notification permission status: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notifications authorized');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ Provisional authorization granted');
    } else {
      print('❌ Notification permission denied');
    }

    // Get FCM token
    String? token = await messaging.getToken();
    if (token != null) {
      print('🔑 FCM Token Generated:');
      print('================================================');
      print(token);
      print('================================================');
      
      // Save token to file for easy copying
      try {
        final file = File('fcm_token.txt');
        await file.writeAsString('FCM Token (${DateTime.now()}):\n$token');
        print('💾 Token saved to fcm_token.txt');
      } catch (e) {
        print('⚠️ Could not save token to file: $e');
      }
    } else {
      print('❌ Failed to get FCM token');
      return;
    }

    // Set up local notifications
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
        
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print('📱 Local notifications initialized');

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      print('📢 Android notification channel created');
    }

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received:');
      print('  Title: ${message.notification?.title}');
      print('  Body: ${message.notification?.body}');
      print('  Data: ${message.data}');
      
      // Show local notification
      _showLocalNotification(flutterLocalNotificationsPlugin, message);
    });

    // Listen for background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App opened from notification:');
      print('  Title: ${message.notification?.title}');
      print('  Body: ${message.notification?.body}');
      print('  Data: ${message.data}');
    });

    // Check for initial message (when app was terminated)
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🎯 App opened from terminated state:');
      print('  Title: ${initialMessage.notification?.title}');
      print('  Body: ${initialMessage.notification?.body}');
      print('  Data: ${initialMessage.data}');
    }

    print('🎉 FCM Debug Test Setup Complete!');
    print('');
    print('📋 Test Instructions:');
    print('1. Copy the FCM token from above');
    print('2. Use Firebase Console or server to send test notification');
    print('3. Check console for message reception logs');
    print('');
    print('🔧 Testing with curl:');
    print('Replace YOUR_FCM_TOKEN and YOUR_SERVER_KEY below:');
    print('');
    print('curl -X POST https://fcm.googleapis.com/fcm/send \\');
    print('  -H "Authorization: key=YOUR_SERVER_KEY" \\');
    print('  -H "Content-Type: application/json" \\');
    print('  -d \'{');
    print('    "to": "$token",');
    print('    "notification": {');
    print('      "title": "Test Notification",');
    print('      "body": "FCM is working!"');
    print('    },');
    print('    "data": {');
    print('      "test": "true"');
    print('    }');
    print('  }\'');
    
  } catch (e, stackTrace) {
    print('❌ Error during FCM setup: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> _showLocalNotification(
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  RemoteMessage message,
) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: false,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    message.notification.hashCode,
    message.notification?.title,
    message.notification?.body,
    platformChannelSpecifics,
  );
  
  print('📱 Local notification shown');
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📨 Background message: ${message.notification?.title}');
}
