# Admin Login Fix Guide

## Issue Overview

The admin login functionality in the Flutter application is not working correctly. After login, the app freezes when clicking on functions. This document provides a step-by-step guide to fix the issues.

## Root Causes

1. **Table Name Case Mismatch**: The API was using uppercase "Admins" in queries, but SQLite uses lowercase "admins".
2. **JWT Token Handling**: The token wasn't being stored properly or consistently used in API requests.
3. **Error Handling**: Poor error handling caused the UI to freeze rather than display helpful messages.
4. **Session Persistence**: Admin session wasn't persisted across app restarts.

## Solution Steps

### 1. Fix the API Server

#### A. Run the fix script we created:

```bash
cd d:\gv\api-server
node fix-admin-login-freeze.js
```

This script:
- Ensures the admin table exists with correct structure
- Creates a test admin user if needed
- Fixes the admin login endpoint to use lowercase "admins"
- Properly generates JWT tokens with adminId in the payload
- Implements proper admin authentication middleware

#### B. Verify the admin table structure:

```javascript
// SQLite table should be lowercase "admins"
CREATE TABLE IF NOT EXISTS admins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  name TEXT,
  email TEXT,
  role TEXT DEFAULT 'admin',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
```

#### C. Test the login API endpoint:

```bash
curl -X POST http://localhost:5000/api/admin/admin-login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin", "password":"admin123"}'
```

### 2. Fix the Flutter App

#### A. Update LocalStorageService

Add these methods to `lib/services/local_storage_service.dart`:

```dart
// Admin token storage
static const String _adminTokenKey = 'admin_token';

Future<void> saveAdminToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_adminTokenKey, token);
}

Future<String?> getAdminToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_adminTokenKey);
}

Future<void> clearAdminToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_adminTokenKey);
}
```

#### B. Update AdminApiService

Modify `lib/services/admin_api_service.dart`:

```dart
void setAuthToken(String token) {
  _authToken = token;
  print('🔑 [AdminApiService] Auth token set: ${token.substring(0, min(15, token.length))}...'); 
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

// Add this helper method
int min(int a, int b) => a < b ? a : b;
```

#### C. Update AdminAuthNotifier

Modify `lib/providers/admin_providers.dart`:

```dart
// Update AdminAuthNotifier constructor to use LocalStorageService
final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  final apiService = ref.watch(adminApiServiceProvider);
  final localStorage = ref.read(Provider<LocalStorageService>((ref) => LocalStorageService()));
  return AdminAuthNotifier(apiService, localStorage);
});

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
    final token = await _localStorage.getAdminToken();
    if (token != null && token.isNotEmpty) {
      // Set token in API service
      _apiService.setAuthToken(token);
      
      // Set authenticated state
      state = state.copyWith(
        isAuthenticated: true,
        token: token,
        isLoading: false,
      );
    }
  }

  // Update login method
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _apiService.adminLogin(username, password);

      if (result['success']) {
        final data = result['data'];
        
        // Store token in local storage
        await _localStorage.saveAdminToken(data['token']);

        // Update state
        state = state.copyWith(
          isAuthenticated: true,
          token: data['token'],
          adminData: data,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result['error']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed: $e');
      return false;
    }
  }

  // Update logout method
  Future<void> logout({WidgetRef? ref}) async {
    // Clear token from local storage
    await _localStorage.clearAdminToken();
    
    // Clear token from API service
    _apiService.setAuthToken('');
    
    // Reset state
    state = const AdminAuthState();
    
    // Invalidate other providers if needed
    if (ref != null) {
      invalidateAllAdminProviders(ref);
    }
  }
}
```

#### D. Update DashboardStatsProvider

```dart
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final apiService = ref.watch(adminApiServiceProvider);
  final authState = ref.watch(adminAuthProvider);

  // Guard: Ensure authenticated
  if (!authState.isAuthenticated) {
    throw Exception('Not authenticated');
  }
  
  // Guard: Ensure token exists
  if (authState.token == null || authState.token!.isEmpty) {
    throw Exception('No authentication token available');
  }

  // Set token in API service
  apiService.setAuthToken(authState.token!);
  
  // Get dashboard stats
  final result = await apiService.getDashboardStats();
  
  if (result['success'] == false) {
    throw Exception(result['error']);
  }
  
  return result['data'];
});
```

## Testing the Fix

1. Start the API server:
   ```bash
   cd d:\gv\api-server
   node fix-admin-login-freeze.js
   ```

2. Run the Flutter app:
   ```bash
   cd d:\gv
   flutter run
   ```

3. Login with admin credentials:
   - Username: `admin`
   - Password: `admin123`

4. Verify dashboard data loads and navigation between tabs works without freezing.

## Common Issues & Troubleshooting

1. **Server Connection Issues**:
   - Verify server is running on port 5000
   - Check API base URL in `lib/core/config/api_config.dart`

2. **Token Validation Failures**:
   - Ensure JWT secret is consistent between client and server
   - Verify token has adminId in payload

3. **Database Issues**:
   - Check database.db exists and has correct tables
   - Verify admin user exists with correct credentials

4. **UI Freezing**:
   - Check for infinite loops in build methods
   - Ensure async operations don't block the UI thread
   - Use FutureBuilder or AsyncValue properly

## Persistence Between App Restarts

After implementing this fix, the admin login session will persist across app restarts:

1. When user logs in, token is stored in SharedPreferences
2. When app starts, token is retrieved from SharedPreferences
3. If token is valid, user is automatically logged in
4. When user logs out, token is cleared from SharedPreferences
