import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';

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

  // Authentication endpoints
  Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final body = json.encode({'email': email, 'password': password});

    return await http.post(url, headers: _defaultHeaders, body: body);
  }

  Future<http.Response> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? aadharNumber,
    String? district,
    String? block,
    String? ward,
    String? address,
    String? pincode,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final body = json.encode({
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'aadharNumber': aadharNumber,
      'district': district,
      'block': block,
      'ward': ward,
      'address': address,
      'pincode': pincode,
    });

    return await http.post(url, headers: _defaultHeaders, body: body);
  }

  // Departments
  Future<http.Response> getDepartments() async {
    final url = Uri.parse('$baseUrl/departments');
    return await http.get(url, headers: _headers);
  }

  // Categories
  Future<http.Response> getCategories({int? departmentId}) async {
    final queryParams = departmentId != null
        ? '?departmentId=$departmentId'
        : '';
    final url = Uri.parse('$baseUrl/categories$queryParams');
    return await http.get(url, headers: _headers);
  }

  // Subcategories
  Future<http.Response> getSubcategories({int? categoryId}) async {
    final queryParams = categoryId != null ? '?categoryId=$categoryId' : '';
    final url = Uri.parse('$baseUrl/subcategories$queryParams');
    return await http.get(url, headers: _headers);
  }

  // Grievances
  Future<http.Response> createGrievance(
    Map<String, dynamic> grievanceData,
  ) async {
    final url = Uri.parse('$baseUrl/grievances');
    final body = json.encode(grievanceData);
    return await http.post(url, headers: _headers, body: body);
  }

  Future<http.Response> getUserGrievances(int citizenId) async {
    final url = Uri.parse('$baseUrl/grievances?citizenId=$citizenId');
    return await http.get(url, headers: _headers);
  }

  Future<http.Response> getAllGrievances() async {
    final url = Uri.parse('$baseUrl/grievances/all');
    return await http.get(url, headers: _headers);
  }

  Future<http.Response> updateGrievance(
    int id,
    Map<String, dynamic> updateData,
  ) async {
    final url = Uri.parse('$baseUrl/grievances/$id');
    final body = json.encode(updateData);
    return await http.put(url, headers: _headers, body: body);
  }

  // User profile
  Future<http.Response> getUserProfile(int citizenId) async {
    final url = Uri.parse('$baseUrl/citizens/$citizenId');
    return await http.get(url, headers: _headers);
  }

  Future<http.Response> updateUserProfile(
    int citizenId,
    Map<String, dynamic> userData,
  ) async {
    final url = Uri.parse('$baseUrl/citizens/$citizenId');
    final body = json.encode(userData);
    return await http.put(url, headers: _headers, body: body);
  }

  // Feedback
  Future<http.Response> submitFeedback(
    Map<String, dynamic> feedbackData,
  ) async {
    final url = Uri.parse('$baseUrl/feedback');
    final body = json.encode(feedbackData);
    return await http.post(url, headers: _headers, body: body);
  }
}
