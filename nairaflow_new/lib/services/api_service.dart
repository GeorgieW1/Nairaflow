import 'package:dio/dio.dart';
import 'package:nairaflow_new/services/storage_service.dart';

class ApiService {
  static final Dio _dio = Dio();
  static const String _baseUrl =
      'https://nairapay-backend-production.up.railway.app/api';

  static void initialize() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add JWT token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getSecure('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired, handle logout
          _handleTokenExpiry();
        }
        handler.next(error);
      },
    ));

    // Add logging interceptor for development (only in debug mode)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: false, // Don't log 401 errors verbosely (expected after logout)
      // logPrint: (o) => print(o), // Disabled for production
    ));
  }

  static void _handleTokenExpiry() async {
    await StorageService.deleteSecure('jwt_token');
    await StorageService.remove('user_data');
    // Navigate to login screen - this will be handled by the auth provider
  }

  // Generic GET method
  static Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // Generic POST method
  static Future<Response> post(String path,
      {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Auth endpoints
  static Future<Response> register(Map<String, dynamic> data) async {
    try {
      return await _dio.post('/auth/register', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> login(Map<String, dynamic> data) async {
    try {
      return await _dio.post('/auth/login', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> verifyToken() async {
    try {
      return await _dio.get('/auth/me');
    } catch (e) {
      rethrow;
    }
  }

  // Wallet endpoints
  static Future<Response> getWalletBalance() async {
    try {
      return await _dio.get('/wallet/balance');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> fundWallet(Map<String, dynamic> data) async {
    try {
      return await _dio.post('/wallet/fund', data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Service endpoints
  static Future<Response> buyAirtime(Map<String, dynamic> data) async {
    try {
      return await _dio.post('/services/airtime', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> buyData(Map<String, dynamic> data) async {
    try {
      return await _dio.post('/services/data', data: data);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Response> payElectricity(Map<String, dynamic> data) async {
    try {
      return await _dio.post('/services/electricity', data: data);
    } catch (e) {
      rethrow;
    }
  }

  // Transaction endpoints
  static Future<Response> getTransactions(
      {int page = 1, int limit = 20, String? type}) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (type != null) queryParams['type'] = type;
      return await _dio.get('/transactions', queryParameters: queryParams);
    } catch (e) {
      rethrow;
    }
  }

  // Mock responses for development (when backend is not available)
  static Future<Map<String, dynamic>> mockLogin(
      String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    if (email == 'test@nairaflow.com' && password == 'password') {
      return {
        'success': true,
        'token': 'mock_jwt_token_12345',
        'user': {
          'id': '1',
          'name': 'John Doe',
          'email': email,
          'phone': '08012345678',
          'walletBalance': 5000.0,
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
    } else {
      throw Exception('Invalid credentials');
    }
  }

  static Future<Map<String, dynamic>> mockRegister(
      Map<String, dynamic> userData) async {
    await Future.delayed(const Duration(seconds: 1));

    return {
      'success': true,
      'token': 'mock_jwt_token_12345',
      'user': {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': userData['name'],
        'email': userData['email'],
        'phone': userData['phone'],
        'walletBalance': 0.0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }
    };
  }
}
