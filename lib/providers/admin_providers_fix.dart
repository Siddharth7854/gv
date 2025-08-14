import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_api_service_fix.dart';
import '../services/local_storage_service.dart';

// Provider definitions (add these at the top)
final adminApiServiceProvider = Provider<AdminApiServiceFix>((ref) {
  return AdminApiServiceFix();
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  final apiService = ref.watch(adminApiServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return AdminAuthNotifier(apiService, localStorage);
});

// Placeholder providers for missing admin features

// --- Admin Grievances State & Notifier ---
class AdminGrievancesState {
  final List<Map<String, dynamic>> grievances;
  final bool isLoading;
  final String? error;

  const AdminGrievancesState({
    this.grievances = const [],
    this.isLoading = false,
    this.error,
  });

  AdminGrievancesState copyWith({
    List<Map<String, dynamic>>? grievances,
    bool? isLoading,
    String? error,
  }) {
    return AdminGrievancesState(
      grievances: grievances ?? this.grievances,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminGrievancesNotifier extends StateNotifier<AdminGrievancesState> {
  Future<bool> updateGrievanceStatus(
    String grievanceId,
    String newStatus,
    String message,
    List<String> imageUrls, {
    WidgetRef? ref,
  }) async {
    _apiService.setAuthToken(_authState.token ?? '');
    final result = await _apiService.updateGrievanceStatus(
      grievanceId,
      newStatus,
      message,
      imageUrls,
    );
    if (result['success'] == true) {
      // Optionally refresh grievances after update
      await fetchGrievances();
      return true;
    } else {
      state = state.copyWith(error: result['error']?.toString());
      return false;
    }
  }

  final AdminApiServiceFix _apiService;
  final AdminAuthState _authState;

  AdminGrievancesNotifier(this._apiService, this._authState) : super(const AdminGrievancesState());

  Future<void> fetchGrievances() async {
    state = state.copyWith(isLoading: true, error: null);
    _apiService.setAuthToken(_authState.token ?? '');
    final result = await _apiService.getAdminGrievances();
    if (result['success']) {
      final data = result['data'] as List<dynamic>;
      state = state.copyWith(
        grievances: List<Map<String, dynamic>>.from(data),
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result['error']);
    }
  }

  Future<void> addGrievance(String title, String description) async {
    state = state.copyWith(isLoading: true, error: null);
    _apiService.setAuthToken(_authState.token ?? '');
    final result = await _apiService.addAdminGrievance(title, description);
    if (result['success'] == true) {
      await fetchGrievances();
      state = state.copyWith(isLoading: false, error: null);
    } else {
      state = state.copyWith(isLoading: false, error: result['error'] ?? 'Add grievance failed');
    }
  }


}

final adminGrievancesProvider = StateNotifierProvider<AdminGrievancesNotifier, AdminGrievancesState>((ref) {
  final apiService = ref.watch(adminApiServiceProvider);
  final authState = ref.watch(adminAuthProvider);
  return AdminGrievancesNotifier(apiService, authState);
});


// --- Admin Users State & Notifier ---
class AdminUsersState {
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final String? error;

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  AdminUsersState copyWith({
    List<Map<String, dynamic>>? users,
    bool? isLoading,
    String? error,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  Future<void> addUser(String name, String email, String phone, String password) async {
    try {
      _apiService.setAuthToken(_authState.token ?? '');
      final result = await _apiService.addAdminUser(name, email, phone, password);
      if (result['success'] == true) {
        await fetchUsers();
      } else {
        state = state.copyWith(error: result['error'] ?? 'Add user failed');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  // Remove addGrievance from AdminUsersNotifier (should only be in AdminGrievancesNotifier)
  final AdminApiServiceFix _apiService;
  final AdminAuthState _authState;

  AdminUsersNotifier(this._apiService, this._authState) : super(const AdminUsersState());

  Future<void> fetchUsers({bool refresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    _apiService.setAuthToken(_authState.token ?? '');
    final result = await _apiService.getAdminUsers();
    if (result['success']) {
      final data = result['data'] as List<dynamic>;
      state = state.copyWith(
        users: List<Map<String, dynamic>>.from(data),
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result['error']);
    }
  }

  void removeUserOptimistically(String userId) {
    final updatedUsers = state.users.where((u) => u['id'] != userId && u['citizen_id'] != userId).toList();
    state = state.copyWith(users: updatedUsers);
  }

  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      _apiService.setAuthToken(_authState.token ?? '');
      final result = await _apiService.deleteAdminUser(userId);
      if (result['success'] == true) {
        // Optionally refresh users after deletion
        await fetchUsers();
        return {'success': true, 'message': result['message'] ?? 'User deleted'};
      } else {
        return {'success': false, 'error': result['error'] ?? 'Delete failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> updateUserStatus(String userId, String newStatus) async {
    try {
      _apiService.setAuthToken(_authState.token ?? '');
      final result = await _apiService.updateAdminUserStatus(userId, newStatus);
      if (result['success'] == true) {
        // Update local state
        final updatedUsers = state.users.map((u) {
          if (u['id'] == userId || u['citizen_id'] == userId) {
            return {...u, 'status': newStatus};
          }
          return u;
        }).toList();
        state = state.copyWith(users: updatedUsers);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}

final adminUsersProvider = StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  final apiService = ref.watch(adminApiServiceProvider);
  final authState = ref.watch(adminAuthProvider);
  return AdminUsersNotifier(apiService, authState);
});

// --- Admin Chat State & Notifier ---
class AdminChatState {
  final List<Map<String, dynamic>> conversations;
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String? error;

  const AdminChatState({
    this.conversations = const [],
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AdminChatState copyWith({
    List<Map<String, dynamic>>? conversations,
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AdminChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminChatNotifier extends StateNotifier<AdminChatState> {
  final AdminApiServiceFix _apiService;
  final AdminAuthState _authState;

  AdminChatNotifier(this._apiService, this._authState) : super(const AdminChatState());

  Future<void> fetchChatConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    _apiService.setAuthToken(_authState.token ?? '');
    final result = await _apiService.getAdminChat();
    if (result['success']) {
      final data = result['data'] as List<dynamic>;
      state = state.copyWith(
        conversations: List<Map<String, dynamic>>.from(data),
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result['error']);
    }
  }

  Future<void> fetchChatMessages(String conversationId) async {
    state = state.copyWith(isLoading: true, error: null);
    _apiService.setAuthToken(_authState.token ?? '');
    final result = await _apiService.getChatMessages(conversationId);
    if (result['success']) {
      final data = result['data'] as List<dynamic>;
      state = state.copyWith(
        messages: List<Map<String, dynamic>>.from(data),
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result['error']);
    }
  }

  Future<void> sendMessage(String conversationId, String grievanceId, String message) async {
    _apiService.setAuthToken(_authState.token ?? '');
    await _apiService.sendChatMessage(conversationId, grievanceId, message);
    await fetchChatMessages(conversationId);
  }

  Future<void> markConversationAsRead(String conversationId) async {
    _apiService.setAuthToken(_authState.token ?? '');
    await _apiService.markConversationAsRead(conversationId);
    await fetchChatConversations();
  }
}

final adminChatProvider = StateNotifierProvider<AdminChatNotifier, AdminChatState>((ref) {
  final apiService = ref.watch(adminApiServiceProvider);
  final authState = ref.watch(adminAuthProvider);
  return AdminChatNotifier(apiService, authState);
});

final grievanceTrendProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(adminApiServiceProvider);
  final authState = ref.watch(adminAuthProvider);
  if (!authState.isAuthenticated || authState.token == null || authState.token!.isEmpty) {
    throw Exception('Not authenticated');
  }
  apiService.setAuthToken(authState.token!);
  final result = await apiService.getGrievanceTrend();
  if (!result['success']) {
    throw Exception(result['error'] ?? 'Failed to fetch grievance trend');
  }
  return result['data'] as Map<String, dynamic>;
});

final statusDistributionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(adminApiServiceProvider);
  final authState = ref.watch(adminAuthProvider);
  if (!authState.isAuthenticated || authState.token == null || authState.token!.isEmpty) {
    throw Exception('Not authenticated');
  }
  apiService.setAuthToken(authState.token!);
  final result = await apiService.getStatusDistribution();
  if (!result['success']) {
    throw Exception(result['error'] ?? 'Failed to fetch status distribution');
  }
  return result['data'] as Map<String, dynamic>;
});

final performanceMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(adminApiServiceProvider);
  final authState = ref.watch(adminAuthProvider);
  if (!authState.isAuthenticated || authState.token == null || authState.token!.isEmpty) {
    throw Exception('Not authenticated');
  }
  apiService.setAuthToken(authState.token!);
  final result = await apiService.getPerformanceMetrics();
  if (!result['success']) {
    throw Exception(result['error'] ?? 'Failed to fetch performance metrics');
  }
  return result['data'] as Map<String, dynamic>;
});

final recentActivitiesProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiService = ref.watch(adminApiServiceProvider);
  final authState = ref.watch(adminAuthProvider);
  if (!authState.isAuthenticated || authState.token == null || authState.token!.isEmpty) {
    throw Exception('Not authenticated');
  }
  apiService.setAuthToken(authState.token!);
  final result = await apiService.getRecentActivities();
  if (!result['success']) {
    throw Exception(result['error'] ?? 'Failed to fetch recent activities');
  }
  return result['data'] as List<dynamic>;
});

// Alias for dashboard stats provider for compatibility
// --- Dashboard Stats State & Notifier ---
class DashboardStatsState {
  final Map<String, dynamic> stats;
  final bool isLoading;
  final String? error;

  const DashboardStatsState({
    this.stats = const {},
    this.isLoading = false,
    this.error,
  });

  DashboardStatsState copyWith({
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
  }) {
    return DashboardStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Custom getters for dashboard metrics
  int get usersCount => stats['usersCount'] ?? 0;
  int get grievancesCount => stats['grievancesCount'] ?? 0;
  int get resolvedCount => stats['resolvedCount'] ?? 0;
  int get pendingCount => stats['pendingCount'] ?? 0;
  double get resolvedPercentage => stats['resolvedPercentage'] ?? 0.0;
  double get inProgressPercentage => stats['inProgressPercentage'] ?? 0.0;
  double get pendingPercentage => stats['pendingPercentage'] ?? 0.0;
  double get rejectedPercentage => stats['rejectedPercentage'] ?? 0.0;
  int get resolved => stats['resolved'] ?? 0;
  int get inProgress => stats['inProgress'] ?? 0;
  int get pending => stats['pending'] ?? 0;
  int get rejected => stats['rejected'] ?? 0;
}

class DashboardStatsNotifier extends StateNotifier<DashboardStatsState> {
  final AdminApiServiceFix _apiService;
  final AdminAuthState _authState;

  DashboardStatsNotifier(this._apiService, this._authState) : super(const DashboardStatsState());

  Future<void> fetchStats() async {
    state = state.copyWith(isLoading: true, error: null);
    _apiService.setAuthToken(_authState.token ?? '');
    final result = await _apiService.getDashboardStats();
    if (result['success']) {
      final data = result['data'] as Map<String, dynamic>;
      state = state.copyWith(stats: data, isLoading: false, error: null);
    } else {
      state = state.copyWith(isLoading: false, error: result['error']);
    }
  }
}

final dashboardStatsProvider = StateNotifierProvider<DashboardStatsNotifier, DashboardStatsState>((ref) {
  final apiService = ref.watch(adminApiServiceProvider);
  final authState = ref.watch(adminAuthProvider);
  return DashboardStatsNotifier(apiService, authState);
});

// Admin providers fix class

// Admin Authentication State (Fixed)
class AdminAuthState {
  final bool isAuthenticated;
  final String? token;
  final Map<String, dynamic>? adminData;
  final bool isLoading;
  final String? error;

  const AdminAuthState({
    this.isAuthenticated = false,
    this.token,
    this.adminData,
    this.isLoading = false,
    this.error,
  });

  AdminAuthState copyWith({
    bool? isAuthenticated,
    String? token,
    Map<String, dynamic>? adminData,
    bool? isLoading,
    String? error,
  }) {
    return AdminAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      adminData: adminData ?? this.adminData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final AdminApiServiceFix _apiService;
  final LocalStorageService _localStorage;

  AdminAuthNotifier(this._apiService, this._localStorage) : super(const AdminAuthState()) {
    _restoreAdminSession();
  }

  // Restore session from local storage
  Future<void> _restoreAdminSession() async {
    print('🔄 [AdminAuthNotifier] Attempting to restore admin session');
    final token = await _localStorage.getAdminToken();
    if (token != null && token.isNotEmpty) {
      print('🔑 [AdminAuthNotifier] Found stored admin token');
      _apiService.setAuthToken(token);
      state = state.copyWith(isAuthenticated: true, token: token, isLoading: false);
      await _fetchAdminProfile();
    } else {
      print('🔒 [AdminAuthNotifier] No stored admin token found');
    }
  }

  // Fetch admin profile data
  Future<void> _fetchAdminProfile() async {
    try {
      print('👤 [AdminAuthNotifier] Fetching admin profile');
      final result = await _apiService.getAdminProfile();
      if (result['success']) {
        print('✅ [AdminAuthNotifier] Admin profile fetched');
        state = state.copyWith(adminData: result['data']);
      } else {
        print('⚠️ [AdminAuthNotifier] Failed to fetch admin profile: ${result['error']}');
      }
    } catch (e) {
      print('❌ [AdminAuthNotifier] Error fetching admin profile: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    print('🔍 [AdminAuthNotifier] Admin login attempt: $username');
    state = state.copyWith(isLoading: true, error: null);
    try {
      print('📡 [AdminAuthNotifier] Calling API: adminLogin with username=$username');
      final result = await _apiService.adminLogin(username, password);
      print('📥 [AdminAuthNotifier] API Response: $result');
      if (result['success']) {
        final data = result['data'];
        print('✅ [AdminAuthNotifier] Login successful, token received');
        await _localStorage.saveAdminToken(data['token']);
        print('💾 [AdminAuthNotifier] Admin token saved to local storage');
        _apiService.setAuthToken(data['token']);
        state = state.copyWith(isAuthenticated: true, token: data['token'], adminData: data, isLoading: false);
        print('🔐 [AdminAuthNotifier] State updated: isAuthenticated=true, token set');
        return true;
      } else {
        print('❌ [AdminAuthNotifier] Login failed: ${result['error']}');
        state = state.copyWith(isLoading: false, error: result['error']);
        return false;
      }
    } catch (e) {
      print('💥 [AdminAuthNotifier] Exception occurred: $e');
      state = state.copyWith(isLoading: false, error: 'Login failed: $e');
      return false;
    }
  }

  Future<void> logout({WidgetRef? ref}) async {
    print('🚪 [AdminAuthNotifier] Admin logout called');
    await _localStorage.clearAdminToken();
    print('🧹 [AdminAuthNotifier] Admin token cleared from storage');
    _apiService.setAuthToken('');
    state = const AdminAuthState();
    print('🔓 [AdminAuthNotifier] Admin state reset');
  }
}

// Dashboard Stats Provider (Fixed)
final dashboardStatsProviderFixed = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  print('🔄 [DashboardStatsProvider] Called');
  
  final apiService = ref.watch(adminApiServiceProvider);
  final authState = ref.watch(adminAuthProvider);

  print('🔐 [DashboardStatsProvider] Admin Auth State: ${authState.isAuthenticated}');
  
  // Guard: Ensure authenticated
  if (!authState.isAuthenticated) {
    print('❌ [DashboardStatsProvider] Not authenticated, throwing exception');
    throw Exception('Not authenticated');
  }
  
  // Guard: Ensure token exists
  if (authState.token == null || authState.token!.isEmpty) {
    print('❌ [DashboardStatsProvider] No token available, throwing exception');
    throw Exception('No authentication token available');
  }

  print('✅ [DashboardStatsProvider] Setting admin token in API service');
  apiService.setAuthToken(authState.token!);
  
  print('📡 [DashboardStatsProvider] Calling admin dashboard stats API...');
  final result = await apiService.getDashboardStats();
  
  if (!result['success']) {
    print('❌ [DashboardStatsProvider] API error: ${result['error']}');
    throw Exception(result['error']);
  }
  
  print('✅ [DashboardStatsProvider] Dashboard stats retrieved successfully');
  return result['data'];
});

// Local storage service extension (for admin token)
extension AdminTokenStorage on LocalStorageService {
  // Get admin token from storage
  Future<String?> getAdminToken() async {
    return getString('admin_token');
  }
  
  // Save admin token to storage
  Future<void> saveAdminToken(String token) async {
    await setString('admin_token', token);
  }
  
  // Clear admin token from storage
  Future<void> clearAdminToken() async {
    await remove('admin_token');
  }
}
