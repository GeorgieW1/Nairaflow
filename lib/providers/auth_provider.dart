import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nairaflow/models/user.dart';
import 'package:nairaflow/services/auth_service.dart';

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

// Auth provider
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await AuthService.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loginWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await AuthService.loginWithEmailPassword(email, password);
      state = state.copyWith(user: user, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await AuthService.registerWithEmailPassword(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      state = state.copyWith(user: user, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false, error: null);
      } else {
        state = state.copyWith(isLoading: false, error: 'Google sign-in cancelled');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await AuthService.logout();
      state = state.copyWith(user: null, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await AuthService.refreshUserData();
      if (user != null) {
        state = state.copyWith(user: user, error: null);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});