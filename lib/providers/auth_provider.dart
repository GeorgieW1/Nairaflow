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
    bool setUserNull = false,
    bool setErrorNull = false,
  }) {
    return AuthState(
      user: setUserNull ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: setErrorNull ? null : (error ?? this.error),
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
      state = state.copyWith(user: user, isLoading: false, setErrorNull: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loginWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, setErrorNull: true);
    try {
      final user = await AuthService.loginWithEmailPassword(email, password);
      state = state.copyWith(user: user, isLoading: false, setErrorNull: true);
    } catch (e) {
      // Clean up error message (remove "Exception: " prefix)
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, setErrorNull: true);
    try {
      final user = await AuthService.registerWithEmailPassword(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      state = state.copyWith(user: user, isLoading: false, setErrorNull: true);
    } catch (e) {
      // Clean up error message (remove "Exception: " prefix)
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, setErrorNull: true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false, setErrorNull: true);
      } else {
        state = state.copyWith(isLoading: false, error: 'Google sign-in cancelled');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    // Set user to null IMMEDIATELY to stop any ongoing requests
    // Don't set isLoading to prevent router redirect issues
    state = state.copyWith(setUserNull: true, isLoading: false, setErrorNull: true);
    try {
      await AuthService.logout();
      // User already null, just ensure state is clean
      state = state.copyWith(setUserNull: true, isLoading: false, setErrorNull: true);
    } catch (e) {
      // Even if logout fails, keep user as null (already logged out from UI perspective)
      state = state.copyWith(setUserNull: true, isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await AuthService.refreshUserData();
      if (user != null) {
        state = state.copyWith(user: user, setErrorNull: true);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(setErrorNull: true);
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});