import 'package:dio/dio.dart';
import 'api_service.dart';

class ElectricityService {
  static Future<Map<String, dynamic>> verifyMeter({
    required String meterNumber,
    required String disco,
    required String meterType,
  }) async {
    try {
      final response = await ApiService.post(
        '/services/electricity/verify',
        data: {
          'meterNumber': meterNumber,
          'disco': disco,
          'meterType': meterType,
        },
      );
      
      if (response.data['success'] == true) {
        // Return the content/data part which usually contains customer name
        return response.data['content'] ?? response.data['data'] ?? {};
      } else {
        throw Exception(response.data['message'] ?? 'Verification failed');
      }
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? e.response?.data['error'] ?? 'Verification failed';
        throw Exception(message);
      }
      throw Exception(e.toString());
    }
  }
}
