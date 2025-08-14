import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/gov_theme.dart';
import '../../services/local_storage_service.dart';
import '../../services/push_notification_service_export.dart';
import '../../services/sql_server_api_service.dart';

// Notification Settings State
class NotificationSettingsState {
  final Map<String, bool> settings;
  final bool isLoading;
  final String? error;

  const NotificationSettingsState({
    this.settings = const {},
    this.isLoading = false,
    this.error,
  });

  NotificationSettingsState copyWith({
    Map<String, bool>? settings,
    bool? isLoading,
    String? error,
  }) {
    return NotificationSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notification Settings Notifier
class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  final LocalStorageService _localStorage;
  final SqlServerApiService _apiService;

  NotificationSettingsNotifier(this._localStorage, this._apiService)
    : super(const NotificationSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);

    try {
      final settings = await _localStorage.getNotificationSettings();
      state = state.copyWith(settings: settings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notification settings: $e',
      );
    }
  }

  Future<void> updateSetting(String key, bool value) async {
    final updatedSettings = Map<String, bool>.from(state.settings);
    updatedSettings[key] = value;

    state = state.copyWith(settings: updatedSettings);

    try {
      // Save locally
      await _localStorage.saveNotificationSettings(updatedSettings);

      // Update on server
      await _apiService.updateNotificationPreferences(updatedSettings);
    } catch (e) {
      // Revert on error
      final revertedSettings = Map<String, bool>.from(state.settings);
      revertedSettings[key] = !value;
      state = state.copyWith(
        settings: revertedSettings,
        error: 'Failed to update setting: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final notificationSettingsProvider =
    StateNotifierProvider<
      NotificationSettingsNotifier,
      NotificationSettingsState
    >((ref) {
      return NotificationSettingsNotifier(
        LocalStorageService(),
        SqlServerApiService(),
      );
    });

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Clear any previous errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationSettingsProvider.notifier).clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: GovTheme.background,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: GovTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _buildHeaderCard(),

                  const SizedBox(height: 24),

                  // Notification Categories
                  _buildNotificationCategory(
                    'Grievance Updates',
                    'Get notified about status changes in your grievances',
                    Icons.assignment,
                    'grievance_updates',
                    settingsState.settings['grievance_updates'] ?? true,
                  ),

                  const SizedBox(height: 16),

                  _buildNotificationCategory(
                    'Chat Messages',
                    'Receive notifications for new chat messages',
                    Icons.chat_bubble,
                    'chat_messages',
                    settingsState.settings['chat_messages'] ?? true,
                  ),

                  const SizedBox(height: 16),

                  _buildNotificationCategory(
                    'Admin Alerts',
                    'Important announcements from administration',
                    Icons.admin_panel_settings,
                    'admin_alerts',
                    settingsState.settings['admin_alerts'] ?? true,
                  ),

                  const SizedBox(height: 16),

                  _buildNotificationCategory(
                    'Reminders',
                    'Reminders for follow-ups and deadlines',
                    Icons.schedule,
                    'reminders',
                    settingsState.settings['reminders'] ?? true,
                  ),

                  const SizedBox(height: 32),

                  // Sound & Vibration Settings
                  Text(
                    'Sound & Vibration',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: GovTheme.darkGray,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildSoundVibrationSetting(
                    'Sound',
                    'Play notification sounds',
                    Icons.volume_up,
                    'sound',
                    settingsState.settings['sound'] ?? true,
                  ),

                  const SizedBox(height: 16),

                  _buildSoundVibrationSetting(
                    'Vibration',
                    'Vibrate on notifications',
                    Icons.vibration,
                    'vibration',
                    settingsState.settings['vibration'] ?? true,
                  ),

                  const SizedBox(height: 32),

                  // Additional Actions
                  _buildActionButtons(),

                  // Error Display
                  if (settingsState.error != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorCard(settingsState.error!),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: GovTheme.headerGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: GovTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stay Connected',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize your notification preferences',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildNotificationCategory(
    String title,
    String description,
    IconData icon,
    String key,
    bool value,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: GovTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GovTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: GovTheme.primaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: GovTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: GovTheme.neutralGray,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              ref
                  .read(notificationSettingsProvider.notifier)
                  .updateSetting(key, newValue);
            },
            activeColor: GovTheme.primaryBlue,
            activeTrackColor: GovTheme.primaryBlue.withValues(alpha: 0.3),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildSoundVibrationSetting(
    String title,
    String description,
    IconData icon,
    String key,
    bool value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GovTheme.borderGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: GovTheme.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: GovTheme.darkGray,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: GovTheme.neutralGray,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              ref
                  .read(notificationSettingsProvider.notifier)
                  .updateSetting(key, newValue);
            },
            activeColor: GovTheme.primaryBlue,
            activeTrackColor: GovTheme.primaryBlue.withValues(alpha: 0.3),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Test Immediate Notification Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _testNotification,
            icon: const Icon(Icons.notification_add),
            label: const Text('Test Immediate Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GovTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Test Scheduled Background Notification Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _testScheduledNotification,
            icon: const Icon(Icons.schedule),
            label: const Text('Test Background Notification (5s)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GovTheme.successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Test Notification When App Closed
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _testClosedAppNotification,
            icon: const Icon(Icons.mobile_off),
            label: const Text('Test Closed App Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GovTheme.warningAmber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Clear All Notifications Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _clearAllNotifications,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All Notifications'),
            style: OutlinedButton.styleFrom(
              foregroundColor: GovTheme.neutralGray,
              side: BorderSide(color: GovTheme.neutralGray),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Show Notification Info Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showNotificationInfo,
            icon: const Icon(Icons.info_outline),
            label: const Text('Show Notification Info'),
            style: OutlinedButton.styleFrom(
              foregroundColor: GovTheme.primaryBlue,
              side: BorderSide(color: GovTheme.primaryBlue),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GovTheme.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GovTheme.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: GovTheme.errorRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.roboto(fontSize: 14, color: GovTheme.errorRed),
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(notificationSettingsProvider.notifier).clearError();
            },
            icon: Icon(Icons.close, color: GovTheme.errorRed, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _testNotification() async {
    try {
      await PushNotificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Government Employee Portal',
        body: 'Test notification - Your notification settings are working!',
        scheduledTime: DateTime.now().add(const Duration(seconds: 2)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Test notification scheduled!'),
            backgroundColor: GovTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification: $e'),
            backgroundColor: GovTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await PushNotificationService.clearAllNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications cleared!'),
            backgroundColor: GovTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear notifications: $e'),
            backgroundColor: GovTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _testScheduledNotification() async {
    try {
      await PushNotificationService.testScheduledNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Background notification scheduled for 5 seconds!',
            ),
            backgroundColor: GovTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule notification: $e'),
            backgroundColor: GovTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _testClosedAppNotification() async {
    try {
      await PushNotificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
        title: 'App Closed Test',
        body: 'यह notification app बंद होने पर भी show होगा!',
        scheduledTime: DateTime.now().add(const Duration(seconds: 10)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'App close test scheduled! Close app in 10 seconds.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule closed app test: $e'),
            backgroundColor: GovTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showNotificationInfo() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: GovTheme.primaryBlue),
              const SizedBox(width: 8),
              const Text('Notification Information'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Service Status', 'Local Notifications Active'),
              _buildInfoRow('Background Support', 'Enabled'),
              _buildInfoRow('Scheduled Notifications', 'Enabled'),
              _buildInfoRow('Platform', 'Flutter Local Notifications'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GovTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Test Features:\n'
                  '• Immediate notification test\n'
                  '• Background notification (5s delay)\n'
                  '• Closed app notification (10s delay)\n'
                  '• Clear all notifications',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: GovTheme.neutralGray)),
        ],
      ),
    );
  }
}
