import 'package:dio/dio.dart';
import 'package:nairaflow/services/api_service.dart';

class EpinService {
  // Service for handling E-pin transactions
  static Future<List<dynamic>> getEpinPlans(String category) async {
    try {
      final response = await ApiService.get('/services/epin/plans/$category');
      return response.data['plans'] ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> purchaseEpin({
    required String category,
    required int quantity,
    required double amount,
    String? phone,
  }) async {
    try {
      final response = await ApiService.post(
        '/services/epin/purchase',
        data: {
          'category': category,
          'quantity': quantity,
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
