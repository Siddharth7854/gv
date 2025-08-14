import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/local_storage_service.dart';
import '../services/sql_server_api_service.dart';
import '../services/notification_manager.dart';
import 'simple_auth_state.dart';

class SimpleAuthNotifier extends StateNotifier<SimpleAuthState> {
  final SqlServerApiService _apiService;
  final LocalStorageService _localStorage;

  SimpleAuthNotifier(this._apiService, this._localStorage)
    : super(SimpleAuthState());

  Future<void> checkAuthStatus() async {
    debugPrint('[SimpleAuthNotifier] checkAuthStatus called');
    try {
      // Add timeout to prevent hanging
      final result = await Future.any([
        _performAuthCheck(),
        Future.delayed(const Duration(seconds: 5), () => 'timeout'),
      ]);

      if (result == 'timeout') {
        debugPrint(
          '[SimpleAuthNotifier] checkAuthStatus: TIMEOUT - Setting unauthenticated',
        );
        state = SimpleAuthState(isAuthenticated: false, user: null);
        return;
      }
    } catch (e) {
      debugPrint('[SimpleAuthNotifier] checkAuthStatus: Exception $e');
      state = state.copyWith(
        isAuthenticated: false,
        user: null,
        error: e.toString(),
      );
    }
  }

  Future<String> _performAuthCheck() async {
    final token = await _localStorage.getToken();
    final user = await _localStorage.getUser();
    debugPrint(
      '[SimpleAuthNotifier] checkAuthStatus: token=${token != null ? "EXISTS" : "NULL"}, user=${user != null ? "EXISTS(${user.fullName})" : "NULL"}',
    );

    if (token != null && user != null) {
      _apiService.setAuthToken(token);
      debugPrint(
        '[SimpleAuthNotifier] checkAuthStatus: Setting Authenticated state',
      );
      state = SimpleAuthState(isAuthenticated: true, user: user);
    } else {
      debugPrint(
        '[SimpleAuthNotifier] checkAuthStatus: Setting Unauthenticated state',
      );
      state = SimpleAuthState(isAuthenticated: false, user: null);
    }
    return 'completed';
  }

  Future<void> login(String phone, String password) async {
    debugPrint('[SimpleAuthNotifier] login called');
    state = SimpleAuthState(
      isAuthenticated: false,
      isLoading: true,
      user: null,
      error: null,
    );

    try {
      final response = await _apiService.login(phone, password);
      debugPrint('[SimpleAuthNotifier] login: API response received');

      final token = response['token'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      final user = User(
        userId: userData['userId'] as String,
        email: userData['email'] as String,
        fullName: userData['fullName'] as String,
        role: 'citizen',
        createdAt: DateTime.now(),
        photoUrl: userData['photoUrl'] as String?,
      );

      debugPrint('[SimpleAuthNotifier] login: Saving token and user locally');
      await _localStorage.saveToken(token);
      await _localStorage.saveUser(user);
      _apiService.setAuthToken(token);

      debugPrint('[SimpleAuthNotifier] login: Authenticated, updating state');
      debugPrint(
        '[SimpleAuthNotifier] User created: ${user.fullName}, userId: ${user.userId}',
      );

      // Create completely new state object
      final newState = SimpleAuthState(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        error: null,
      );
      debugPrint('[SimpleAuthNotifier] Creating new state: $newState');

      // Force state update
      state = newState;
      debugPrint('[SimpleAuthNotifier] State updated to: $state');
      debugPrint('[SimpleAuthNotifier] State hashCode: ${state.hashCode}');
      debugPrint(
        '[SimpleAuthNotifier] Provider should notify listeners now...',
      );

      // Update notification manager with user context
      try {
        await NotificationManager.updateUserContext(
          userId: user.userId,
          userRole: user.role,
        );
        debugPrint(
          '[SimpleAuthNotifier] Notification context updated for user: ${user.fullName}',
        );
      } catch (e) {
        debugPrint(
          '[SimpleAuthNotifier] Error updating notification context: $e',
        );
      }

      // Additional debugging
      Future.delayed(Duration(milliseconds: 100), () {
        debugPrint('[SimpleAuthNotifier] After delay - current state: $state');
      });
    } catch (e) {
      debugPrint('[SimpleAuthNotifier] login: Exception $e');
      state = SimpleAuthState(
        isAuthenticated: false,
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<void> logout() async {
    debugPrint('[SimpleAuthNotifier] logout called');

    // Clear notification context before logout
    try {
      await NotificationManager.clearUserContext();
      debugPrint('[SimpleAuthNotifier] Notification context cleared');
    } catch (e) {
      debugPrint(
        '[SimpleAuthNotifier] Error clearing notification context: $e',
      );
    }

    await _localStorage.clearToken();
    await _localStorage.clearUser();
    _apiService.clearAuthToken();

    // Force complete state reset
    state = SimpleAuthState(
      isAuthenticated: false,
      isLoading: false,
      user: null,
      error: null,
      timestamp: DateTime.now(),
    );
    debugPrint('[SimpleAuthNotifier] logout completed - state reset');
  }

  Future<void> updateUser(User updatedUser) async {
    try {
      await _localStorage.saveUser(updatedUser);
      state = SimpleAuthState(
        isAuthenticated: state.isAuthenticated,
        isLoading: state.isLoading,
        user: updatedUser,
        error: state.error,
      );
      debugPrint('[SimpleAuthNotifier] User updated: ${updatedUser.fullName}');
    } catch (e) {
      debugPrint('[SimpleAuthNotifier] updateUser error: $e');
    }
  }

  void clearError() {
    state = SimpleAuthState(
      isAuthenticated: state.isAuthenticated,
      isLoading: state.isLoading,
      user: state.user,
      error: null,
    );
  }

  // Debug method to test state changes
  void debugSetAuthenticated() {
    debugPrint(
      '[SimpleAuthNotifier] DEBUG: Manually setting authenticated state',
    );
    final testUser = User(
      userId: 'test',
      email: 'test@test.com',
      fullName: 'Test User',
      role: 'citizen',
      createdAt: DateTime.now(),
    );
    debugPrint(
      '[SimpleAuthNotifier] DEBUG: Creating test state with user: ${testUser.fullName}',
    );
    final newDebugState = SimpleAuthState(
      isAuthenticated: true,
      isLoading: false,
      user: testUser,
      error: null,
    );
    debugPrint('[SimpleAuthNotifier] DEBUG: New state object: $newDebugState');
    state = newDebugState;
    debugPrint('[SimpleAuthNotifier] DEBUG: State set to: $state');
  }
}

// Provider instances
final simpleSqlServerApiServiceProvider = Provider<SqlServerApiService>((ref) {
  return SqlServerApiService();
});

final simpleLocalStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final simpleAuthProvider =
    StateNotifierProvider<SimpleAuthNotifier, SimpleAuthState>((ref) {
      final apiService = ref.watch(simpleSqlServerApiServiceProvider);
      final localStorage = ref.watch(simpleLocalStorageServiceProvider);
      return SimpleAuthNotifier(apiService, localStorage);
    });

// Computed providers
final simpleCurrentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(simpleAuthProvider);
  return authState.user;
});

final simpleIsAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(simpleAuthProvider);
  return authState.isAuthenticated;
});
