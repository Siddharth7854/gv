import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class AdminApiServiceFix {
  // Add new user (admin only)
  Future<Map<String, dynamic>> addAdminUser(String name, String email, String phone, String password) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/users/add');
      final body = json.encode({
        'fullName': name,
        'email': email,
        'phoneNumber': phone,
        'password': password,
      });
      final response = await http.post(url, headers: _headers, body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to add user'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Add new grievance (admin only)
  Future<Map<String, dynamic>> addAdminGrievance(String title, String description) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/grievances/add');
      final body = json.encode({
        'title': title,
        'description': description,
      });
      final response = await http.post(url, headers: _headers, body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to add grievance'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  // Delete admin user
  Future<Map<String, dynamic>> deleteAdminUser(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/users/delete');
      final body = json.encode({'userId': userId});
      final response = await http.post(url, headers: _headers, body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message'] ?? 'User deleted'};
      } else {
        return {'success': false, 'error': 'Failed to delete user'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Update admin user status
  Future<Map<String, dynamic>> updateAdminUserStatus(String userId, String newStatus) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/users/update-status');
      final body = json.encode({'userId': userId, 'newStatus': newStatus});
      final response = await http.post(url, headers: _headers, body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message'] ?? 'Status updated'};
      } else {
        return {'success': false, 'error': 'Failed to update user status'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  // Update grievance status with optional image URLs
  Future<Map<String, dynamic>> updateGrievanceStatus(
    String grievanceId,
    String newStatus,
    String message,
    List<String> imageUrls,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/grievances/update-status');
      final body = json.encode({
        'grievanceId': grievanceId,
        'newStatus': newStatus,
        'message': message,
        'imageUrls': imageUrls,
      });
      final response = await http.post(url, headers: _headers, body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to update grievance status'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  // Get chat messages for a conversation
  Future<Map<String, dynamic>> getChatMessages(String conversationId) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/chat/messages/$conversationId');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch chat messages'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Send a chat message
  Future<Map<String, dynamic>> sendChatMessage(String conversationId, String grievanceId, String message) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/chat/send');
      final body = json.encode({
        'conversationId': conversationId,
        'grievanceId': grievanceId,
        'message': message,
      });
      final response = await http.post(url, headers: _headers, body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to send message'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Mark a conversation as read
  Future<Map<String, dynamic>> markConversationAsRead(String conversationId) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/chat/mark-read/$conversationId');
      final response = await http.post(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to mark conversation as read'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  // Get Admin Chat
  Future<Map<String, dynamic>> getAdminChat() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/chat');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Authentication failed. Please login again.'};
      } else {
        return {'success': false, 'error': 'Failed to fetch chat data'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get Grievance Trend
  Future<Map<String, dynamic>> getGrievanceTrend() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/grievance-trend');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Authentication failed. Please login again.'};
      } else {
        return {'success': false, 'error': 'Failed to fetch grievance trend'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get Status Distribution
  Future<Map<String, dynamic>> getStatusDistribution() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/status-distribution');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Authentication failed. Please login again.'};
      } else {
        return {'success': false, 'error': 'Failed to fetch status distribution'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get Performance Metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/performance-metrics');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Authentication failed. Please login again.'};
      } else {
        return {'success': false, 'error': 'Failed to fetch performance metrics'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get Recent Activities
  Future<Map<String, dynamic>> getRecentActivities() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/recent-activities');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Authentication failed. Please login again.'};
      } else {
        return {'success': false, 'error': 'Failed to fetch recent activities'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  // Get Admin Grievances
  Future<Map<String, dynamic>> getAdminGrievances() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/grievances');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // If data is a Map, wrap in a List
        if (data is List) {
          return {'success': true, 'data': data};
        } else if (data is Map) {
          return {'success': true, 'data': [data]};
        } else {
          return {'success': false, 'error': 'Unexpected data format'};
        }
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Authentication failed. Please login again.'};
      } else {
        return {'success': false, 'error': 'Failed to fetch grievances'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get Admin Users
  Future<Map<String, dynamic>> getAdminUsers() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/users');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // If data is a Map, wrap in a List
        if (data is List) {
          return {'success': true, 'data': data};
        } else if (data is Map) {
          return {'success': true, 'data': [data]};
        } else {
          return {'success': false, 'error': 'Unexpected data format'};
        }
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Authentication failed. Please login again.'};
      } else {
        return {'success': false, 'error': 'Failed to fetch users'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  // ...existing code...

  // Get Admin Profile
  Future<Map<String, dynamic>> getAdminProfile() async {
    try {
    final url = Uri.parse('$baseUrl/api/admin/profile');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch admin profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  static String get baseUrl => ApiConfig.baseUrl;

  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
    print('🔑 [AdminApiService] Auth token set: ${token.substring(0, 15)}...'); 
  }

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
      print('🔑 [AdminApiService] Using auth token in headers');
    } else {
      print('⚠️ [AdminApiService] No auth token available for request');
    }
    return headers;
  }

  // Admin Authentication
  Future<Map<String, dynamic>> adminLogin(
    String username,
    String password,
  ) async {
    try {
      print('🌐 API Base URL: $baseUrl');
      final url = Uri.parse('$baseUrl/api/admin/admin-login');
      print('📍 Request URL: $url');

      final body = json.encode({'username': username, 'password': password});
      print('📤 Request Body: $body');

      final response = await http.post(
        url,
        headers: _defaultHeaders,
        body: body,
      );

      print('📨 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          // Store the token immediately
          setAuthToken(data['token']);
          
          // Decode JWT to check for admin_id
          final parts = data['token'].split('.');
          if (parts.length == 3) {
            final payload = utf8.decode(
              base64Url.decode(base64Url.normalize(parts[1])),
            );
            final payloadMap = json.decode(payload);
            print('🔍 JWT Payload: $payloadMap');
            
            // Check for adminId (our server uses adminId)
            if (payloadMap['adminId'] != null) {
              return {'success': true, 'data': data};
            } else {
              print('⚠️ JWT missing adminId, but continuing with token');
              return {'success': true, 'data': data};
            }
          } else {
            print('⚠️ Invalid token format, but continuing');
            return {'success': true, 'data': data};
          }
        }
        return {'success': false, 'error': 'No token received'};
      } else {
        return {'success': false, 'error': 'Invalid credentials'};
      }
    } catch (e) {
      print('💥 Network Error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('🔍 Fetching admin dashboard stats...');
      final url = Uri.parse('$baseUrl/api/admin/dashboard-stats');
      print('📍 Admin Dashboard URL: $url');
      
      final headers = _headers;
      print('🔑 Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('📨 Admin Dashboard Response Status: ${response.statusCode}');
      print('📨 Admin Dashboard Response Body: ${response.body.substring(0, min(100, response.body.length))}...');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed: Token may be invalid or expired');
        return {
          'success': false, 
          'error': 'Authentication failed. Please login again.'
        };
      } else {
        return {'success': false, 'error': 'Failed to fetch dashboard stats'};
      }
    } catch (e) {
      print('💥 Error fetching dashboard stats: $e');
      return {'success': false, 'error': 'Error: $e'};
    }
  }
  
  // Helper for string truncation
  int min(int a, int b) => a < b ? a : b;
}
