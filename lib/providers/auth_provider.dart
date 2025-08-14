import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/local_storage_service.dart';
import '../services/sql_server_api_service.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final SqlServerApiService _apiService;
  final LocalStorageService _localStorage;

  AuthNotifier(this._apiService, this._localStorage)
    : super(const AuthInitial());

  Future<void> checkAuthStatus() async {
    debugPrint('[AuthNotifier] checkAuthStatus called');
    try {
      final token = await _localStorage.getToken();
      final user = await _localStorage.getUser();
      debugPrint(
        '[AuthNotifier] checkAuthStatus: token=${token != null ? "EXISTS" : "NULL"}, user=${user != null ? "EXISTS(${user.fullName})" : "NULL"}',
      );
      if (token != null && user != null) {
        _apiService.setAuthToken(token);
        debugPrint(
          '[AuthNotifier] checkAuthStatus: Setting Authenticated state',
        );
        state = AuthAuthenticated(user);
      } else {
        debugPrint(
          '[AuthNotifier] checkAuthStatus: Setting Unauthenticated state',
        );
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      debugPrint('[AuthNotifier] checkAuthStatus: Exception $e');
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String phone, String password) async {
    debugPrint('[AuthNotifier] login called');
    state = const AuthLoading();

    try {
      final response = await _apiService.login(phone, password);
      debugPrint('[AuthNotifier] login: API response received');

      final token = response['token'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      // Create User object from response
      final user = User(
        userId: userData['citizen_id'].toString(),
        email: userData['email'] as String,
        fullName: userData['full_name'] as String,
        role: 'citizen',
        createdAt:
            DateTime.now(), // Use current time since API doesn't return created_at in login
        photoUrl: userData['photo_url'] as String?,
      );

      // Save credentials locally
      debugPrint('[AuthNotifier] login: Saving token and user locally');
      await _localStorage.saveToken(token);
      await _localStorage.saveUser(user);
      _apiService.setAuthToken(token);

      debugPrint('[AuthNotifier] login: Authenticated, updating state');
      debugPrint(
        '[AuthNotifier] User created: ${user.fullName}, userId: ${user.userId}',
      );

      // Explicitly create new state object and assign
      final newState = AuthAuthenticated(user);
      debugPrint('[AuthNotifier] Creating new state: $newState');
      state = newState;
      debugPrint('[AuthNotifier] State updated to: $state');
      debugPrint('[AuthNotifier] Provider should notify listeners now...');
    } catch (e) {
      debugPrint('[AuthNotifier] login: Exception $e');
      state = AuthError('Login failed: ${e.toString()}');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String aadharNumber,
    required String district,
    required String block,
    required String ward,
    required String address,
    required String pincode,
  }) async {
    state = const AuthLoading();

    try {
      await _apiService.register({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'aadharNumber': aadharNumber,
        'district': district,
        'block': block,
        'ward': ward,
        'address': address,
        'pincode': pincode,
        'password': password,
      });

      // Registration successful - show success
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError('Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _localStorage.clearToken();
    await _localStorage.clearUser();
    _apiService.clearAuthToken();
    state = const AuthUnauthenticated();
  }

  Future<void> updateUser(User updatedUser) async {
    try {
      // Save updated user locally
      await _localStorage.saveUser(updatedUser);
      // Update state
      state = AuthAuthenticated(updatedUser);
      debugPrint('[AuthNotifier] User updated: ${updatedUser.fullName}');
    } catch (e) {
      debugPrint('[AuthNotifier] updateUser error: $e');
    }
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  // Debug method to test state changes
  void debugSetAuthenticated() {
    debugPrint('[AuthNotifier] DEBUG: Manually setting authenticated state');
    final testUser = User(
      userId: 'test',
      email: 'test@test.com',
      fullName: 'Test User',
      role: 'citizen',
      createdAt: DateTime.now(),
    );
    final newState = AuthAuthenticated(testUser);
    debugPrint('[AuthNotifier] DEBUG: Creating test state: $newState');
    state = newState;
    debugPrint('[AuthNotifier] DEBUG: State set to: $state');
  }
}

// Provider instances
final sqlServerApiServiceProvider = Provider<SqlServerApiService>((ref) {
  return SqlServerApiService();
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(sqlServerApiServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return AuthNotifier(apiService, localStorage);
});

// Computed providers
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated;
});
