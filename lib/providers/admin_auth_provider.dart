import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple admin auth provider for demo purposes
class AdminAuth {
  bool isLoggedIn = false;

  bool login(String username, String password) {
    if (username == 'admin' && password == 'admin123') {
      isLoggedIn = true;
      return true;
    }
    return false;
  }

  void logout() {
    isLoggedIn = false;
  }
}

final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, AdminAuth>((
  ref,
) {
  return AdminAuthNotifier();
});

class AdminAuthNotifier extends StateNotifier<AdminAuth> {
  AdminAuthNotifier() : super(AdminAuth());

  bool login(String username, String password) {
    return state.login(username, password);
  }

  void logout() {
    state.logout();
  }
}
