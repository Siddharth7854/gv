import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_fcm_service.dart';
import '../services/notification_manager.dart';

class TestFCMTokenMobile extends StatefulWidget {
  const TestFCMTokenMobile({super.key});

  @override
  State<TestFCMTokenMobile> createState() => _TestFCMTokenMobileState();
}

class _TestFCMTokenMobileState extends State<TestFCMTokenMobile> {
  String? _fcmToken;
  bool _isLoading = false;
  String _status = 'Ready to test FCM notifications';

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing FCM...';
    });

    try {
      await NotificationManager.initialize();
      await _getFCMToken();
      setState(() {
        _status = 'FCM initialized successfully. Ready for testing!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing FCM: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getFCMToken() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting FCM token...';
    });

    try {
      final token = await FirebaseFCMService.getTokenForTesting();
      setState(() {
        _fcmToken = token;
        _status = token != null 
          ? 'FCM Token ready! Copy it from debug console.'
          : 'Failed to get FCM token';
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting token: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showTestNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Sending test notification...';
    });

    try {
      await FirebaseFCMService.showTestNotification();
      setState(() {
        _status = 'Test notification sent! Check your dropdown.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error sending test notification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyTokenToClipboard() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCM Token copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Token Testing'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLoading ? Icons.hourglass_empty : Icons.info,
                          color: const Color(0xFF1E3A8A),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FCM Token Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.token,
                          color: Color(0xFF1E3A8A),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'FCM Token',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_fcmToken != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
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
                      ElevatedButton.icon(
                        onPressed: _copyTokenToClipboard,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Token'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'No token available. Check debug console for details.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: Color(0xFF1E3A8A),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Testing Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Get Token Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getFCMToken,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Get FCM Token'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Test Notification Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _showTestNotification,
                        icon: const Icon(Icons.notifications),
                        label: const Text('Test Dropdown Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Color(0xFF1E3A8A),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'How to Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Get FCM Token (copy from debug console)\n'
                      '2. Go to Firebase Console\n'
                      '3. Project: grievance-app-11680\n'
                      '4. Cloud Messaging > Send test message\n'
                      '5. Paste token in "FCM registration token"\n'
                      '6. Send message and check dropdown\n'
                      '7. Also test local dropdown notification',
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
