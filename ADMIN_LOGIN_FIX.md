# Admin Login and Dashboard Fix

This document provides a comprehensive solution to fix the admin login and dashboard freezing issues in the Flutter application.

## Problem Summary

1. The admin login functionality is broken due to case-sensitive table name inconsistencies in SQLite.
2. After login, the app freezes when clicking on different functions.
3. The `dashboardStatsProvider` throws errors when loading dashboard data.

## Causes Identified

1. Table name mismatch between schema (`admins` lowercase) and queries (`Admins` uppercase).
2. JWT token handling issues in `AdminApiService` and `AdminAuthNotifier`.
3. The Flutter app doesn't properly handle error states or set auth tokens consistently.
4. Lack of persistent storage for admin tokens.

## Solution Components

### 1. Server-Side Fixes (Already Applied)

- Fixed table name casing in SQL queries (changed `Admins` to `admins`).
- Added `eslint-disable` comments to SQL queries.
- Verified admin table structure in SQLite database.
- Ensured JWT tokens contain the correct `adminId` field.

### 2. API Service Fixes

In `AdminApiService`:

- Improved token management with proper storage and retrieval.
- Added better error handling and logging.
- Fixed JWT token validation.

### 3. Provider Fixes

In `AdminAuthNotifier`:

- Added token persistence using `LocalStorageService`.
- Implemented session restoration on app start.
- Improved error handling and state management.

### 4. Integration Tests

- Created test scripts to verify admin login.
- Added test for dashboard stats API.
- Created end-to-end test for admin login flow.

## Implementation Instructions

### Step 1: Fix Server Code

1. Open `d:\gv\api-server\fix-admin-login-freeze.js` and run it to test and fix the admin login API:

```bash
cd d:\gv\api-server
node fix-admin-login-freeze.js
```

2. Verify that the admin login works and returns a valid JWT token.

### Step 2: Fix Flutter App Code

1. Update `AdminApiService` with token handling improvements:

```dart
// In admin_api_service.dart

// Update the setAuthToken method
void setAuthToken(String token) {
  _authToken = token;
  print('🔑 [AdminApiService] Auth token set: ${token.substring(0, min(15, token.length))}...'); 
}

// Update the _headers getter
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

// Add this helper method
int min(int a, int b) => a < b ? a : b;
```

2. Add admin token storage to `LocalStorageService`:

```dart
// In local_storage_service.dart

static const String _adminTokenKey = 'admin_token';

Future<void> saveAdminToken(String token) async {
  print('[LocalStorage] Saving admin token: ${token.length} chars');
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_adminTokenKey, token);
  print('[LocalStorage] Admin token saved successfully');
}

Future<String?> getAdminToken() async {
  print('[LocalStorage] Getting admin token from storage');
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(_adminTokenKey);
  print(
    '[LocalStorage] Retrieved admin token: ${token != null ? "${token.length} chars" : "NULL"}',
  );
  return token;
}

Future<void> clearAdminToken() async {
  print('[LocalStorage] Clearing admin token');
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_adminTokenKey);
  print('[LocalStorage] Admin token cleared');
}
```

3. Update `AdminAuthNotifier` in `admin_providers.dart`:

```dart
// In admin_providers.dart

// Update AdminAuthNotifier constructor to use LocalStorageService
final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService();
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  final apiService = ref.watch(adminApiServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return AdminAuthNotifier(apiService, localStorage);
});

// Update AdminAuthNotifier class
class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final AdminApiService _apiService;
  final LocalStorageService _localStorage;

  AdminAuthNotifier(this._apiService, this._localStorage) 
      : super(const AdminAuthState()) {
    // Attempt to restore admin session on initialization
    _restoreAdminSession();
  }

  // Add this method to restore session
  Future<void> _restoreAdminSession() async {
    print('🔄 [AdminAuthNotifier] Attempting to restore admin session');
    
    final token = await _localStorage.getAdminToken();
    if (token != null && token.isNotEmpty) {
      print('🔑 [AdminAuthNotifier] Found stored admin token');
      
      // Set token in API service
      _apiService.setAuthToken(token);
      
      // Set authenticated state
      state = state.copyWith(
        isAuthenticated: true,
        token: token,
        isLoading: false,
      );
    } else {
      print('🔒 [AdminAuthNotifier] No stored admin token found');
    }
  }

  // Update login method to save token to storage
  Future<bool> login(String username, String password) async {
    print('🔍 [AdminAuthNotifier] Admin login attempt: $username');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('📡 [AdminAuthNotifier] Calling API: adminLogin');
      final result = await _apiService.adminLogin(username, password);
      print('📥 [AdminAuthNotifier] API Response: $result');

      if (result['success']) {
        final data = result['data'];
        print('✅ [AdminAuthNotifier] Login successful, token received');

        // Store token in local storage
        await _localStorage.saveAdminToken(data['token']);
        print('💾 [AdminAuthNotifier] Admin token saved to local storage');

        // Update state
        state = state.copyWith(
          isAuthenticated: true,
          token: data['token'],
          adminData: data,
          isLoading: false,
        );
        
        print('🔐 [AdminAuthNotifier] State updated: isAuthenticated=true');
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

  // Update logout method to clear token from storage
  Future<void> logout({WidgetRef? ref}) async {
    print('🚪 [AdminAuthNotifier] Admin logout called');
    
    // Clear token from local storage
    await _localStorage.clearAdminToken();
    print('🧹 [AdminAuthNotifier] Admin token cleared from storage');
    
    // Clear token from API service
    _apiService.setAuthToken('');
    
    // Reset state
    state = const AdminAuthState();
    print('🔓 [AdminAuthNotifier] Admin state reset');
    
    // Only invalidate admin providers, not user auth
    if (ref != null) {
      invalidateAllAdminProviders(ref);
      print('🧹 [AdminAuthNotifier] Admin providers invalidated');
    }
  }
}
```

4. Fix `dashboardStatsProvider` in `admin_providers.dart`:

```dart
// In admin_providers.dart

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
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
  
  if (result['success'] == false) {
    print('❌ [DashboardStatsProvider] API error: ${result['error']}');
    throw Exception(result['error']);
  }
  
  print('✅ [DashboardStatsProvider] Dashboard stats retrieved successfully');
  return result['data'];
});
```

### Step 3: Test the Integration

1. Run the server fix script to verify admin login API:

```bash
cd d:\gv\api-server
node fix-admin-login-freeze.js
```

2. Run the Flutter app and test admin login:

```bash
cd d:\gv
flutter run
```

3. Log in with admin credentials:
   - Username: `admin`
   - Password: `admin123`

4. Verify that the dashboard loads correctly and all functions work without freezing.

## Expected Behavior After Fix

1. Admin login works properly with correct credentials.
2. Admin token is stored in local storage for persistence.
3. Dashboard data loads correctly without errors.
4. App doesn't freeze when navigating between tabs.
5. Admin session persists across app restarts.
