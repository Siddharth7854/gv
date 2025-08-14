import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform-specific API Configuration
/// Handles different API endpoints for different platforms
class ApiConfig {
  /// Get base API URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine
      return 'http://10.0.2.2:5000';
    } else {
      // iOS, Windows, macOS, Linux use localhost
      return 'http://localhost:5000';
    }
  }

  /// Get API base URL with /api suffix
  static String get apiBaseUrl => '$baseUrl/api';

  /// Build image URL for uploads
  static String buildImageUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }

    // Remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$cleanPath';
  }

  /// Build profile photo URL
  static String buildProfileUrl(String photoUrl) {
    if (photoUrl.startsWith('http')) {
      return photoUrl;
    }
    return '$baseUrl/uploads/profiles/$photoUrl';
  }

  /// Current platform info for debugging
  static String get platformInfo {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
