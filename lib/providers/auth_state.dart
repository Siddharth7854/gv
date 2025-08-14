import '../models/user.dart';

// Pattern matching extension for AuthState
extension AuthStateWhen on AuthState {
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(User user) authenticated,
    required T Function() unauthenticated,
    required T Function(String message) error,
  }) {
    if (this is AuthInitial) return initial();
    if (this is AuthLoading) return loading();
    if (this is AuthAuthenticated) {
      return authenticated((this as AuthAuthenticated).user);
    }
    if (this is AuthUnauthenticated) return unauthenticated();
    if (this is AuthError) return error((this as AuthError).message);
    throw Exception('Unknown auth state: $this');
  }
}

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

extension AuthStateX on AuthState {
  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isLoading => this is AuthLoading;
  bool get hasError => this is AuthError;

  User? get user {
    if (this is AuthAuthenticated) {
      return (this as AuthAuthenticated).user;
    }
    return null;
  }

  String? get errorMessage {
    if (this is AuthError) {
      return (this as AuthError).message;
    }
    return null;
  }
}
