import '../models/user.dart';

class SimpleAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;
  final DateTime timestamp; // Add timestamp to force state changes

  SimpleAuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  SimpleAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? error,
  }) {
    return SimpleAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
      timestamp: DateTime.now(), // Force new timestamp
    );
  }

  @override
  String toString() {
    return 'SimpleAuthState(isAuthenticated: $isAuthenticated, isLoading: $isLoading, user: ${user?.fullName}, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimpleAuthState &&
        other.isAuthenticated == isAuthenticated &&
        other.isLoading == isLoading &&
        other.user == user &&
        other.error == error &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return isAuthenticated.hashCode ^
        isLoading.hashCode ^
        user.hashCode ^
        error.hashCode ^
        timestamp.hashCode;
  }
}
