import 'package:dio/dio.dart';
import 'api_service.dart';

class OTPService {
  // Send OTP to user's email
  static Future<Map<String, dynamic>> sendOTP() async {
    try {
      final response = await ApiService.post('/auth/send-otp');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      return {
        'success': false,
        'error': 'Network error: ${e.message}'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred: $e'
      };
    }
  }

  // Verify OTP code
  static Future<Map<String, dynamic>> verifyOTP(String otp) async {
    try {
      final response = await ApiService.post(
        '/auth/verify-otp',
        data: {'otp': otp},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      return {
        'success': false,
        'error': 'Network error: ${e.message}'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred: $e'
      };
    }
  }
}
