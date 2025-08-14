
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class AdminApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

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


  // Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('🔍 Fetching admin dashboard stats...');
      final url = Uri.parse('$baseUrl/api/admin/dashboard-stats');
      print('📍 Admin Dashboard URL: $url');
      print('🔑 Headers: $_headers');

      final response = await http.get(url, headers: _headers);

      print('📨 Admin Dashboard Response Status: ${response.statusCode}');
      print('📨 Admin Dashboard Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // API already returns with success wrapper, so just return it as-is
        return data;
      } else {
        return {'success': false, 'error': 'Failed to fetch dashboard stats'};
      }
    } catch (e) {
      print('💥 Admin dashboard stats error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Monthly Trends
  Future<Map<String, dynamic>> getMonthlyTrends() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/monthly-trends');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch monthly trends'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Category Distribution
  Future<Map<String, dynamic>> getCategoryDistribution() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/category-distribution');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch category distribution',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get All Grievances
  Future<Map<String, dynamic>> getGrievances({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final url = Uri.parse(
        '$baseUrl/api/admin/grievances',
      ).replace(queryParameters: queryParams);

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch grievances'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Update Grievance Status
  Future<Map<String, dynamic>> updateGrievanceStatus(
    String grievanceId,
    String newStatus,
    String? comments,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/admin/grievances/$grievanceId/status',
      );
      final body = json.encode({'status': newStatus, 'comments': comments});

      final response = await http.put(url, headers: _headers, body: body);

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

  // Update Grievance Status with Images (Progress Photos)
  Future<Map<String, dynamic>> updateGrievanceStatusWithImages(
    String grievanceId,
    String newStatus,
    String? comments,
    List<String> imageUrls,
  ) async {
    try {
      // Use the correct endpoint for updating with images
      final url = Uri.parse(
        '$baseUrl/api/admin/grievances/$grievanceId/update-with-images',
      );
      final body = json.encode({
        'status': newStatus,
        'comments': comments,
        'progress_photos': imageUrls, // Include the progress photos
      });

      print(
        '🔍 Updating grievance $grievanceId with ${imageUrls.length} images',
      );
      print('📤 Request body: $body');

      final response = await http.put(url, headers: _headers, body: body);

      print('📨 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': 'Failed to update grievance status with images',
        };
      }
    } catch (e) {
      print('💥 Error updating grievance status with images: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get All Users
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final url = Uri.parse(
        '$baseUrl/api/admin/users',
      ).replace(queryParameters: queryParams);

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch users'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Update User Status
  Future<Map<String, dynamic>> updateUserStatus(
    String userId,
    String newStatus,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/users/$userId/status');
      final body = json.encode({'status': newStatus});

      final response = await http.put(url, headers: _headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to update user status'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Delete User
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/users/$userId');
      final response = await http.delete(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'User deleted successfully',
          'data': data['deletedUser'],
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'User not found'};
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Cannot delete user',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to delete user',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get Grievance Details
  Future<Map<String, dynamic>> getGrievanceDetails(String grievanceId) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/grievances/$grievanceId');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch grievance details'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get User Details
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/users/$userId');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to fetch user details'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Generate Reports
  Future<Map<String, dynamic>> generateReport(String reportType) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/reports/$reportType');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to generate report'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Chat Management Methods
  Future<Map<String, dynamic>> getChatConversations() async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/chat/conversations');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch chat conversations',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getChatMessages(String conversationId) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/chat/$conversationId/messages');
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

  Future<Map<String, dynamic>> sendAdminMessage(
    String conversationId,
    String grievanceId,
    String message,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/chat/send');
      final body = json.encode({
        'conversation_id': conversationId,
        'grievance_id': grievanceId,
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

  Future<Map<String, dynamic>> markConversationAsRead(
    String conversationId,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/admin/chat/$conversationId/mark-read',
      );
      final response = await http.post(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': 'Failed to mark conversation as read',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
