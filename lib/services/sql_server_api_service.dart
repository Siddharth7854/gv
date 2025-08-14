import 'package:dio/dio.dart';
import '../models/grievance_new.dart';
import '../core/config/api_config.dart';

class SqlServerApiService {
  static String get baseUrl => ApiConfig.apiBaseUrl;
  late Dio _dio;
  String? _authToken;

  SqlServerApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add request interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          print('API Error: ${error.message}');
          if (error.response != null) {
            print('Status Code: ${error.response?.statusCode}');
            print('Response Data: ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'phoneNumber': phone, 'password': password},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/auth/register', data: userData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Logout errors are typically not critical
      print('Logout error (non-critical): $e');
    } finally {
      clearAuthToken();
    }
  }

  // Grievance methods
  Future<List<Grievance>> getGrievancesByCitizen(int citizenId) async {
    try {
      final response = await _dio.get('/grievances/citizen/$citizenId');
      final List<dynamic> grievancesJson = response.data['grievances'];
      return grievancesJson.map((json) => Grievance.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Grievance> getGrievanceById(int grievanceId) async {
    try {
      final response = await _dio.get('/grievances/$grievanceId');
      return Grievance.fromJson(response.data['grievance']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGrievanceDetails(int grievanceId) async {
    try {
      final response = await _dio.get('/grievances/$grievanceId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGrievanceTimeline(
    int grievanceId,
  ) async {
    try {
      final response = await _dio.get('/grievances/$grievanceId/timeline');
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['timeline'] ?? []);
      }
      return [];
    } catch (e) {
      print('Timeline API error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> submitGrievance(
    Map<String, dynamic> grievanceData,
  ) async {
    try {
      final response = await _dio.post('/grievances', data: grievanceData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateGrievance(
    int grievanceId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _dio.put(
        '/grievances/$grievanceId',
        data: updates,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteGrievance(int grievanceId) async {
    try {
      final response = await _dio.delete('/grievances/$grievanceId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      return List<Map<String, dynamic>>.from(response.data['categories']);
    } catch (e) {
      rethrow;
    }
  }

  // Dashboard
  Future<Map<String, dynamic>> getDashboardStats(int citizenId) async {
    try {
      final response = await _dio.get('/dashboard/stats/$citizenId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Profile methods
  Future<Map<String, dynamic>> getProfile(int citizenId) async {
    try {
      final response = await _dio.get('/auth/profile/$citizenId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    int citizenId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _dio.put(
        '/auth/profile/$citizenId',
        data: profileData,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changePassword(
    int citizenId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await _dio.put(
        '/auth/change-password',
        data: {
          'citizenId': citizenId,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(
    int citizenId,
    String filePath,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath),
        'citizen_id': citizenId.toString(),
      });

      final response = await _dio.post('/upload/profile-photo', data: formData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeProfilePhoto(int citizenId) async {
    try {
      final response = await _dio.delete('/upload/profile-photo/$citizenId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Admin methods
  Future<Map<String, dynamic>> adminLogin(
    String username,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/admin/login',
        data: {'username': username, 'password': password},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllGrievances() async {
    try {
      final response = await _dio.get('/admin/grievances');
      return List<Map<String, dynamic>>.from(response.data['grievances']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateGrievanceStatus(
    int grievanceId,
    String status,
    String? reason,
  ) async {
    try {
      final response = await _dio.put(
        '/admin/grievances/$grievanceId/status',
        data: {'status': status, 'reason': reason},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Image upload for grievance updates
  Future<Map<String, dynamic>> updateGrievanceWithImages(
    int grievanceId,
    String status,
    String? comments,
    List<String> imagePaths,
  ) async {
    try {
      FormData formData = FormData();

      // Add form fields
      formData.fields.add(MapEntry('status', status));
      if (comments != null && comments.isNotEmpty) {
        formData.fields.add(MapEntry('comments', comments));
      }

      // Add image files
      for (int i = 0; i < imagePaths.length; i++) {
        String filePath = imagePaths[i];
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              filePath,
              filename:
                  'update_image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          ),
        );
      }

      final response = await _dio.put(
        '/admin/grievances/$grievanceId/update-with-images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Utility methods
  String getProfilePhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return '';
    }

    if (photoUrl.startsWith('http')) {
      return photoUrl;
    }

    return ApiConfig.buildProfileUrl(photoUrl);
  }

  String getMediaFileUrl(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return '';
    }

    if (filePath.startsWith('http')) {
      return filePath;
    }

    // Handle different file path formats
    String fileName = filePath;

    // If it's a full path, extract just the filename
    if (filePath.contains('/') || filePath.contains('\\')) {
      fileName = filePath.split(RegExp(r'[/\\]')).last;
    }

    // Convert file path to URL for uploaded files
    return ApiConfig.buildImageUrl('uploads/$fileName');
  }

  Future<bool> checkServerConnection() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // FCM Token Management
  Future<Map<String, dynamic>> updateFCMToken(
    String fcmToken, {
    String? userId,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/fcm-token',
        data: {'fcm_token': fcmToken, 'user_id': userId, 'platform': 'flutter'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'FCM token updated successfully',
          'data': response.data,
        };
      } else {
        return {'success': false, 'error': 'Failed to update FCM token'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> removeFCMToken(String fcmToken) async {
    try {
      final response = await _dio.delete(
        '/auth/fcm-token',
        data: {'fcm_token': fcmToken},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'FCM token removed successfully'};
      } else {
        return {'success': false, 'error': 'Failed to remove FCM token'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Notification Preferences
  Future<Map<String, dynamic>> updateNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    try {
      final response = await _dio.put(
        '/auth/notification-preferences',
        data: {'preferences': preferences},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Notification preferences updated successfully',
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to update notification preferences',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final response = await _dio.get('/auth/notification-preferences');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': 'Failed to get notification preferences',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
