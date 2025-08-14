import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/push_notification_service_export.dart';

class FCMTokenTestScreen extends StatefulWidget {
  const FCMTokenTestScreen({super.key});

  @override
  State<FCMTokenTestScreen> createState() => _FCMTokenTestScreenState();
}

class _FCMTokenTestScreenState extends State<FCMTokenTestScreen> {
  String? _fcmToken;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getFCMToken();
  }

  Future<void> _getFCMToken() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Initialize Firebase first
      await PushNotificationService.initialize();

      // Get FCM token
      final token = await PushNotificationService.getToken();

      setState(() {
        _fcmToken = token;
        _isLoading = false;
      });

      if (token != null) {
        print('🔥 FCM Registration Token:');
        print('=' * 50);
        print(token);
        print('=' * 50);
        print(
          '✅ Firebase Console में इस token को use करें test notifications के लिए',
        );
        print(
          '📍 Path: Firebase Console > Cloud Messaging > Send test message',
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to get FCM token: $e';
        _isLoading = false;
      });
      print('❌ FCM Token Error: $e');
    }
  }

  Future<void> _copyToken() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FCM Token copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Token Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Cloud Messaging Token',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Getting FCM Token...'),
                  ],
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_error!),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _getFCMToken,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_fcmToken != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Token Retrieved Successfully!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'FCM Registration Token:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: SelectableText(
                        _fcmToken!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _copyToken,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Token'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'How to Test',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text('1. Copy the FCM token above'),
                            Text('2. Go to Firebase Console'),
                            Text(
                              '3. Navigate: Cloud Messaging > Send test message',
                            ),
                            Text(
                              '4. Paste the token in the "FCM registration token" field',
                            ),
                            Text('5. Write your test message and send'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
