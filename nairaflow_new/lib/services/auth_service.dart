import 'package:nairaflow/models/user.dart';
import 'package:nairaflow/services/api_service.dart';
import 'package:nairaflow/services/storage_service.dart';

class AuthService {

  // Email/Password Authentication
  static Future<User> loginWithEmailPassword(String email, String password) async {
    try {
      final response = await ApiService.login({
        'email': email,
        'password': password,
      });
      
      if (response.data['success'] == true) {
        // Store JWT token securely
        await StorageService.storeSecure('jwt_token', response.data['token']);
        
        // Store user data
        final userData = response.data['user'] as Map<String, dynamic>;
        await StorageService.storeJson('user_data', userData);
        
        return User.fromJson(userData);
      } else {
        // Handle specific error messages from backend
        final message = response.data['message'] ?? '';
        if (message.toLowerCase().contains('password')) {
          throw Exception('🔒 Incorrect password. Please try again.');
        } else if (message.toLowerCase().contains('not found') || message.toLowerCase().contains('account')) {
          throw Exception('⚠️ Account not found. Check your login details and try again.');
        } else {
          throw Exception('⚠️ Something went wrong. Please try again later.');
        }
      }
    } catch (e) {
      // If it's already a formatted error, pass it through
      if (e.toString().contains('🔒') || e.toString().contains('⚠️') || e.toString().contains('🌐')) {
        rethrow;
      }
      
      // Handle actual network errors (connection issues)
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection timed out')) {
        throw Exception('🌐 Network error. Please check your internet connection.');
      }
      
      // For DioException with response (bad credentials, validation errors, etc.)
      // The error is already handled above in the if/else block
      // So if we're here, it's an unexpected error
      throw Exception('⚠️ Something went wrong. Please try again later.');
    }
  }

  static Future<User> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final userData = {
        'name': name,
        'email': email,
        'password': password,
      };

      final response = await ApiService.register(userData);
      
      if (response.data['success'] == true) {
        // Backend doesn't return token on register, so login after registration
        return await loginWithEmailPassword(email, password);
      } else {
        // Handle specific error messages from backend
        final message = response.data['message'] ?? '';
        if (message.toLowerCase().contains('exists') || message.toLowerCase().contains('already')) {
          throw Exception('⚠️ This email is already registered. Please login instead.');
        } else {
          throw Exception('⚠️ Registration failed. Please try again later.');
        }
      }
    } catch (e) {
      // If it's already a formatted error, pass it through
      if (e.toString().contains('🔒') || e.toString().contains('⚠️') || e.toString().contains('🌐')) {
        rethrow;
      }
      
      // Handle actual network errors (connection issues)
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection timed out')) {
        throw Exception('🌐 Network error. Please check your internet connection.');
      }
      
      // For DioException with response (validation errors, etc.)
      // The error is already handled above in the if/else block
      // So if we're here, it's an unexpected error
      throw Exception('⚠️ Registration failed. Please try again later.');
    }
  }

  // Google Sign-In (simplified for demo)
  static Future<User?> signInWithGoogle() async {
    try {
      // For demo purposes, create a mock Google user
      final userData = {
        'name': 'Google User',
        'email': 'googleuser@gmail.com',
        'phone': '08012345678',
        'firebase_uid': 'google_demo_uid',
      };

      // Send to backend for user creation/sync
      final response = await ApiService.mockRegister(userData);
      
      if (response['success'] == true) {
        // Store JWT token securely
        await StorageService.storeSecure('jwt_token', response['token']);
        
        // Store user data
        final userDataResponse = response['user'] as Map<String, dynamic>;
        await StorageService.storeJson('user_data', userDataResponse);
        
        return User.fromJson(userDataResponse);
      }

      return null;
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  // Check if user is logged in
  static Future<User?> getCurrentUser() async {
    try {
      final token = await StorageService.getSecure('jwt_token');
      if (token == null) return null;

      final userData = await StorageService.getJson('user_data');
      if (userData == null) return null;

      return User.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      // Clear stored data
      await StorageService.deleteSecure('jwt_token');
      await StorageService.remove('user_data');
      await StorageService.remove('transactions');
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  // Refresh user data
  static Future<User?> refreshUserData() async {
    try {
      final token = await StorageService.getSecure('jwt_token');
      if (token == null) return null;

      // Fetch fresh data from API
      final response = await ApiService.verifyToken();
      
      if (response.data['success'] == true) {
        final userData = response.data['user'] as Map<String, dynamic>;
        await StorageService.storeJson('user_data', userData);
        return User.fromJson(userData);
      }

      return null;
    } catch (e) {
      // If API call fails, return cached data
      final userData = await StorageService.getJson('user_data');
      if (userData == null) return null;
      return User.fromJson(userData);
    }
  }
}