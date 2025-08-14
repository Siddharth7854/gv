import 'package:flutter/material.dart';
import 'package:gv/services/push_notification_service_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase and get FCM token
    await PushNotificationService.initialize();
    final token = await PushNotificationService.getToken();

    if (token != null) {
      print('🔥 FCM Registration Token:');
      print('=' * 50);
      print(token);
      print('=' * 50);
      print(
        '✅ Firebase Console में इस token को use करें test notifications के लिए',
      );
      print('📍 Path: Firebase Console > Cloud Messaging > Send test message');
    } else {
      print('❌ FCM token not available');
    }
  } catch (e) {
    print('❌ Error getting FCM token: $e');
  }
}
