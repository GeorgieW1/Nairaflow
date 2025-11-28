import 'package:dio/dio.dart';
import 'package:nairaflow_new/services/api_service.dart';

class TVService {
  static Future<Map<String, dynamic>> verifySmartcard({
    required String smartcardNumber,
    required String provider,
  }) async {
    try {
      final response = await ApiService.post(
        '/services/tv/verify',
        data: {
          'smartcardNumber': smartcardNumber,
          'provider': provider,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getTVPlans(String provider) async {
    try {
      final response = await ApiService.get('/services/tv/plans/$provider');
      return response.data['plans'] ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> subscribe({
    required String smartcardNumber,
    required String provider,
    required String bouquetCode,
    required double amount,
    String? phone,
  }) async {
    try {
      final response = await ApiService.post(
        '/services/tv/subscribe',
        data: {
          'smartcardNumber': smartcardNumber,
          'provider': provider,
          'bouquetCode': bouquetCode,
          'amount': amount,
          'phone': phone,
        },
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static String _handleError(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = data is Map ? data['error'] ?? data['message'] : null;

      if (message != null) return message;

      switch (statusCode) {
        case 400:
          return 'Invalid request. Please check your inputs.';
        case 402:
          return 'Insufficient wallet balance. Please fund your wallet.';
        case 404:
          return 'Resource not found.';
        case 503:
          return 'Service temporarily unavailable. Please try again later.';
        case 504:
          return 'Service timeout. Please try again.';
        default:
          return 'An unexpected error occurred. Please try again.';
      }
    }
    return error.toString();
  }
}

