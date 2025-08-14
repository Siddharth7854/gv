
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/grievance.dart';

class LocalStorageService {
  // Generic getString
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Generic setString
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // Generic remove
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';
  static const String _grievancesKey = 'grievances';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _notificationSettingsKey = 'notification_settings';

  // Token management
  Future<void> saveToken(String token) async {
    print('[LocalStorage] Saving token: ${token.length} chars');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('[LocalStorage] Token saved successfully');
  }

  Future<String?> getToken() async {
    print('[LocalStorage] Getting token from storage');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print(
      '[LocalStorage] Retrieved token: ${token != null ? "${token.length} chars" : "NULL"}',
    );
    return token;
  }

  // User management
  Future<void> saveUser(User user) async {
    print('[LocalStorage] Saving user: ${user.fullName}');
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    print('[LocalStorage] User JSON to save: $userJson');
    await prefs.setString(_userKey, userJson);
    print('[LocalStorage] User saved successfully');
  }

  Future<User?> getUser() async {
    print('[LocalStorage] Getting user from storage');
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    print('[LocalStorage] Retrieved user string: $userString');
    if (userString != null) {
      try {
        final userJson = json.decode(userString) as Map<String, dynamic>;
        final user = User.fromJson(userJson);
        print('[LocalStorage] User parsed successfully: ${user.fullName}');
        return user;
      } catch (e) {
        print('[LocalStorage] Error parsing user: $e');
        return null;
      }
    }
    print('[LocalStorage] No user found in storage');
    return null;
  }

  // Grievances management
  Future<void> saveGrievance(Grievance grievance) async {
    final prefs = await SharedPreferences.getInstance();
    final grievances = await getGrievances();
    grievances.add(grievance);
    final grievancesJson = grievances.map((g) => g.toJson()).toList();
    await prefs.setString(_grievancesKey, json.encode(grievancesJson));
  }

  Future<List<Grievance>> getGrievances() async {
    final prefs = await SharedPreferences.getInstance();
    final grievancesString = prefs.getString(_grievancesKey);
    if (grievancesString != null) {
      final grievancesJson = json.decode(grievancesString) as List;
      return grievancesJson
          .map((g) => Grievance.fromJson(g as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Grievance>> getUnsyncedGrievances() async {
    final grievances = await getGrievances();
    return grievances.where((g) => g.isSynced == false).toList();
  }

  Future<void> updateGrievanceSyncStatus(int? localId, int serverId) async {
    final grievances = await getGrievances();
    final index = grievances.indexWhere((g) => g.grievanceId == localId);
    if (index != -1) {
      grievances[index] = grievances[index].copyWith(
        grievanceId: serverId,
        isSynced: true,
      );
      final prefs = await SharedPreferences.getInstance();
      final grievancesJson = grievances.map((g) => g.toJson()).toList();
      await prefs.setString(_grievancesKey, json.encode(grievancesJson));
    }
  }

  // Clear all data
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_grievancesKey);
  }

  // Clear specific data
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Cache management for offline support
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$key', json.encode(data));
  }

  Future<Map<String, dynamic>?> getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString('cache_$key');
    if (cachedString != null) {
      return json.decode(cachedString) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('cache_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // FCM Token management
  Future<void> saveFCMToken(String token) async {
    print('[LocalStorage] Saving FCM token: ${token.length} chars');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
    print('[LocalStorage] FCM token saved successfully');
  }

  Future<String?> getFCMToken() async {
    print('[LocalStorage] Getting FCM token from storage');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_fcmTokenKey);
    print(
      '[LocalStorage] Retrieved FCM token: ${token != null ? "${token.length} chars" : "NULL"}',
    );
    return token;
  }

  Future<void> clearFCMToken() async {
    print('[LocalStorage] Clearing FCM token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fcmTokenKey);
    print('[LocalStorage] FCM token cleared');
  }

  // Notification Settings management
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    print('[LocalStorage] Saving notification settings: $settings');
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = json.encode(settings);
    await prefs.setString(_notificationSettingsKey, settingsJson);
    print('[LocalStorage] Notification settings saved successfully');
  }

  Future<Map<String, bool>> getNotificationSettings() async {
    print('[LocalStorage] Getting notification settings from storage');
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_notificationSettingsKey);

    if (settingsString != null) {
      try {
        final settingsJson =
            json.decode(settingsString) as Map<String, dynamic>;
        final settings = settingsJson.map(
          (key, value) => MapEntry(key, value as bool),
        );
        print('[LocalStorage] Retrieved notification settings: $settings');
        return settings;
      } catch (e) {
        print('[LocalStorage] Error parsing notification settings: $e');
      }
    }

    // Default notification settings
    final defaultSettings = {
      'grievance_updates': true,
      'chat_messages': true,
      'admin_alerts': true,
      'reminders': true,
      'sound': true,
      'vibration': true,
    };
    print(
      '[LocalStorage] Using default notification settings: $defaultSettings',
    );
    return defaultSettings;
  }

  Future<void> clearNotificationSettings() async {
    print('[LocalStorage] Clearing notification settings');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationSettingsKey);
    print('[LocalStorage] Notification settings cleared');
  }
}
