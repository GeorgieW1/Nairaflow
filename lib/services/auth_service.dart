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
        throw Exception('Login failed');
      }
    } catch (e) {
      if (e.toString().contains('DioException')) {
        throw Exception('Login failed: Unable to connect to server');
      }
      throw Exception('Login failed: ${e.toString()}');
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
        throw Exception('Registration failed');
      }
    } catch (e) {
      if (e.toString().contains('DioException')) {
        throw Exception('Registration failed: Unable to connect to server');
      }
      throw Exception('Registration failed: ${e.toString()}');
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