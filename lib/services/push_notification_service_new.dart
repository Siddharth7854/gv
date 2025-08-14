// Comprehensive Local Notification Service
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String? _mockFCMToken;

  // Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('🔔 Notification service already initialized');
      return;
    }

    try {
      debugPrint('🔔 Initializing notification service...');

      // Initialize timezone
      tz.initializeTimeZones();

      // Generate mock FCM token for testing
      _mockFCMToken = _generateMockToken();

      // Initialize local notifications on supported platforms
      if (!kIsWeb) {
        if (Platform.isAndroid || Platform.isIOS) {
          await _initializeLocalNotifications();
          debugPrint('✅ Local notifications initialized for mobile');
        } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          await _initializeDesktopNotifications();
          debugPrint('✅ Desktop notifications initialized');
        } else {
          debugPrint('⚠️ Local notifications not supported on this platform');
        }
      } else {
        debugPrint('⚠️ Local notifications not supported on web platform');
      }

      _initialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
      _initialized = true; // Mark as initialized to prevent retries
    }
  }

  // Initialize local notifications for mobile
  static Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  // Initialize desktop notifications (Windows, macOS, Linux)
  static Future<void> _initializeDesktopNotifications() async {
    try {
      InitializationSettings initSettings;

      if (Platform.isMacOS) {
        // macOS specific initialization
        initSettings = const InitializationSettings(
          macOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        );
      } else {
        // Linux and Windows - use Linux settings (compatible)
        initSettings = const InitializationSettings(
          linux: LinuxInitializationSettings(
            defaultActionName: 'Open notification',
          ),
        );
      }

      // Initialize the plugin for desktop
      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized != null && initialized) {
        debugPrint(
          '✅ Desktop notification service initialized for ${Platform.operatingSystem}',
        );
      } else {
        debugPrint('⚠️ Desktop notification initialization returned false');
      }
    } catch (e) {
      debugPrint('⚠️ Desktop notifications initialization failed: $e');
      // For development, continue without notifications
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to relevant screen
  }

  // Generate mock FCM token
  static String _generateMockToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = kIsWeb
        ? 'web'
        : (Platform.isAndroid ? 'android' : 'desktop');
    return 'mock-fcm-token-$platform-$timestamp-grievance-app-dev';
  }

  // Get FCM token (mock for now)
  static Future<String?> getToken() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (_mockFCMToken != null) {
        debugPrint('🔔 Mock FCM Token: ${_mockFCMToken!.substring(0, 50)}...');
        return _mockFCMToken;
      } else {
        debugPrint('⚠️ Mock FCM Token is null');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Show immediate notification (for testing)
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized || kIsWeb) {
      debugPrint(
        '⚠️ Notifications not available - initialized: $_initialized, isWeb: $kIsWeb',
      );
      return;
    }

    // Windows-specific native notification using PowerShell
    if (Platform.isWindows) {
      try {
        await _showWindowsToastNotification(title, body);
        debugPrint('🔔 Windows Toast notification shown: $title');
        return;
      } catch (e) {
        debugPrint('❌ Windows Toast notification failed: $e');
        // Continue to fallback flutter_local_notifications
      }
    }

    try {
      // Platform-specific notification details for non-Windows platforms
      NotificationDetails notificationDetails;

      if (Platform.isAndroid) {
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'grievance_channel',
              'Grievance Notifications',
              channelDescription: 'Notifications for grievance updates',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            );
        notificationDetails = const NotificationDetails(
          android: androidDetails,
        );
      } else if (Platform.isIOS) {
        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        notificationDetails = const NotificationDetails(iOS: iosDetails);
      } else if (Platform.isMacOS) {
        const DarwinNotificationDetails macDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        notificationDetails = const NotificationDetails(macOS: macDetails);
      } else {
        // For Windows and Linux platforms
        const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
          category: LinuxNotificationCategory.device,
          urgency: LinuxNotificationUrgency.normal,
        );
        notificationDetails = const NotificationDetails(linux: linuxDetails);
      }

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint(
        '🔔 Notification shown successfully: $title (ID: $notificationId)',
      );
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
      debugPrint('❌ Platform: ${Platform.operatingSystem}');

      // Fallback: Show a simple toast-style message
      debugPrint('📄 Fallback notification: $title - $body');
    }
  }

  // Schedule notification (with fallback for platforms that don't support zonedSchedule)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_initialized || kIsWeb) {
      debugPrint('⚠️ Scheduled notifications not available');
      return;
    }

    try {
      // Platform-specific notification details
      NotificationDetails notificationDetails;

      if (Platform.isAndroid) {
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'grievance_scheduled',
              'Scheduled Grievance Notifications',
              channelDescription:
                  'Scheduled notifications for grievance updates',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            );
        notificationDetails = const NotificationDetails(
          android: androidDetails,
        );
      } else if (Platform.isIOS) {
        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        notificationDetails = const NotificationDetails(iOS: iosDetails);
      } else {
        // For desktop platforms
        const LinuxNotificationDetails linuxDetails =
            LinuxNotificationDetails();
        notificationDetails = const NotificationDetails(linux: linuxDetails);
      }

      // Check if current platform supports scheduled notifications
      if (Platform.isAndroid || Platform.isIOS) {
        // Use zonedSchedule for mobile platforms
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          notificationDetails,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('⏰ Notification scheduled: $title at $scheduledTime');
      } else {
        // For desktop platforms, simulate delay with Future.delayed
        final delay = scheduledTime.difference(DateTime.now());
        if (delay.isNegative) {
          // If scheduled time is in the past, show immediately
          await showNotification(title: title, body: body, payload: payload);
          debugPrint('⏰ Past scheduled time, shown immediately: $title');
        } else {
          // Schedule using Future.delayed (works but won't persist across app restarts)
          Future.delayed(delay, () async {
            await showNotification(title: title, body: body, payload: payload);
          });
          debugPrint(
            '⏰ Desktop notification scheduled: $title in ${delay.inSeconds}s',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    if (!_initialized || kIsWeb) {
      debugPrint('⚠️ Clear notifications not available');
      return;
    }

    try {
      await _localNotifications.cancelAll();
      debugPrint('🧹 All notifications cleared');
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  // Test notification (for development)
  static Future<void> testNotification() async {
    await showNotification(
      title: 'Government Grievance System',
      body: 'Notification service is working! आपकी शिकायत का अपडेट मिला है।',
      payload: 'test_notification',
    );
  }

  // Test scheduled notification (5 seconds from now)
  static Future<void> testScheduledNotification() async {
    final scheduleTime = DateTime.now().add(const Duration(seconds: 5));
    await scheduleNotification(
      id: 999,
      title: 'Scheduled Test',
      body: 'यह 5 सेकंड बाद का scheduled notification है!',
      scheduledTime: scheduleTime,
      payload: 'scheduled_test',
    );
  }

  // Windows-specific toast notification using PowerShell
  static Future<void> _showWindowsToastNotification(
    String title,
    String body,
  ) async {
    try {
      // PowerShell script to show Windows 10/11 Toast notification
      final script =
          '''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

\$form = New-Object System.Windows.Forms.Form
\$form.Text = "$title"
\$form.Size = New-Object System.Drawing.Size(400,150)
\$form.StartPosition = "CenterScreen"
\$form.TopMost = \$true
\$form.FormBorderStyle = "FixedDialog"
\$form.MaximizeBox = \$false
\$form.MinimizeBox = \$false

\$label = New-Object System.Windows.Forms.Label
\$label.Location = New-Object System.Drawing.Point(20,20)
\$label.Size = New-Object System.Drawing.Size(350,60)
\$label.Text = "$body"
\$label.Font = New-Object System.Drawing.Font("Segoe UI",10)
\$form.Controls.Add(\$label)

\$button = New-Object System.Windows.Forms.Button
\$button.Location = New-Object System.Drawing.Point(160,90)
\$button.Size = New-Object System.Drawing.Size(80,30)
\$button.Text = "OK"
\$button.Add_Click({
    \$form.Close()
})
\$form.Controls.Add(\$button)

\$timer = New-Object System.Windows.Forms.Timer
\$timer.Interval = 5000
\$timer.Add_Tick({
    \$form.Close()
    \$timer.Stop()
})
\$timer.Start()

[void]\$form.ShowDialog()
''';

      // Execute PowerShell script
      final result = await Process.run('powershell.exe', [
        '-Command',
        script,
      ], runInShell: true);

      if (result.exitCode == 0) {
        debugPrint('✅ Windows Toast notification executed successfully');
      } else {
        debugPrint('⚠️ Windows Toast notification failed: ${result.stderr}');
      }
    } catch (e) {
      debugPrint('❌ Windows Toast notification error: $e');
      rethrow;
    }
  }
}
