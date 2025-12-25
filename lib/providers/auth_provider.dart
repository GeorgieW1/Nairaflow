import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
    bool clear = false,
  }) {
    if (clear) {
      return const AuthState();
    }

    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    state = state.copyWith(isLoading: true);

    final token = await StorageService.getSecure('jwt_token');
    final user = await AuthService.getCurrentUser();

    if (token != null && user != null) {
      state = state.copyWith(
        user: user,
        token: token,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loginWithEmailPassword(
      String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user =
          await AuthService.loginWithEmailPassword(email, password);

      final token = await StorageService.getSecure('jwt_token');

      state = state.copyWith(
        user: user,
        token: token,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = state.copyWith(clear: true);
  }

  Future<void> refreshUser() async {
    final user = await AuthService.refreshUserData();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
