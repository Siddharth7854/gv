import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/notification_manager.dart';
import '../../core/config/api_config.dart';

class NotificationTestScreen extends ConsumerStatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  ConsumerState<NotificationTestScreen> createState() =>
      _NotificationTestScreenState();
}

class _NotificationTestScreenState
    extends ConsumerState<NotificationTestScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    _titleController.text = '🔔 Test Notification';
    _bodyController.text = 'This is a test notification from the Flutter app!';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendTestNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      _showError('Please fill in both title and body');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      debugPrint('🔔 Sending test notification to backend...');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/test'),
        headers: {
          'Content-Type': 'application/json',
          // Add auth token if needed
        },
        body: jsonEncode({
          'title': _titleController.text,
          'body': _bodyController.text,
        }),
      );

      debugPrint('📤 Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _lastResult = 'Success! Sent to ${result['sent_count']} users';
        });
        _showSuccess('Notification sent successfully!');
        debugPrint('✅ Notification sent: ${result['message']}');
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _lastResult = 'Error: ${error['error']}';
        });
        _showError('Failed to send: ${error['error']}');
      }
    } catch (e) {
      setState(() {
        _lastResult = 'Exception: $e';
      });
      _showError('Error: $e');
      debugPrint('❌ Error sending notification: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendLocalTestNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await NotificationManager.showTestNotification(
        title: _titleController.text,
        body: _bodyController.text,
        payload: 'test_notification',
      );

      setState(() {
        _lastResult = 'Local notification sent successfully';
      });
      _showSuccess('Local notification sent!');
    } catch (e) {
      setState(() {
        _lastResult = 'Local notification error: $e';
      });
      _showError('Local notification error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNotificationToken() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await NotificationManager.refreshToken();
      final token = NotificationManager.currentToken;

      setState(() {
        _lastResult = 'Token refreshed: ${token?.substring(0, 20)}...';
      });
      _showSuccess('Token refreshed successfully!');
    } catch (e) {
      setState(() {
        _lastResult = 'Token refresh error: $e';
      });
      _showError('Token refresh error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Notification Testing'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notification Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Notification Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow(
                      'Initialized',
                      notificationState.isInitialized,
                    ),
                    _buildStatusRow(
                      'Has Token',
                      notificationState.currentToken != null,
                    ),
                    if (notificationState.currentToken != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Token: ${notificationState.currentToken!.substring(0, 30)}...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Notification Form
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 Create Test Notification',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Body',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.message),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '🚀 Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendTestNotification,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Send to All Users (Backend)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendLocalTestNotification,
                      icon: const Icon(Icons.phone_android),
                      label: const Text('Send Local Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _refreshNotificationToken,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh FCM Token'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Last Result
            if (_lastResult != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Last Result',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _lastResult!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Instructions
            Card(
              elevation: 4,
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Instructions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Make sure your API server is running (npm start)\n'
                      '2. "Send to All Users" sends via Firebase to all registered users\n'
                      '3. "Send Local Test" shows platform-specific notification\n'
                      '4. "Refresh FCM Token" updates your device token\n'
                      '5. Check console logs for detailed debugging info',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.blue[700]),
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

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
