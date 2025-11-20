import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nairaflow/services/storage_service.dart';
import 'package:nairaflow/screens/wallet/paystack_payment_screen.dart';

class PaystackService {
  static const String baseUrl = 'https://nairapay-backend-production.up.railway.app/api';
  static const String publicKey = 'pk_test_b867557d197b144374335c8bcb107b2f38adfc3c';

  /// Initialize Paystack plugin (call this in main.dart)
  static Future<void> initialize() async {
    // No initialization needed for pay_with_paystack
  }

  /// Fund wallet using Paystack
  /// Returns a map with success status, message, and new balance
  static Future<Map<String, dynamic>> fundWallet({
    required BuildContext context,
    required double amount,
    required String userEmail,
    required String paymentMethod,
  }) async {
    try {
      // Validate email
      if (userEmail.isEmpty) {
        return {
          'success': false,
          'message': '⚠️ Email is required for payment.',
        };
      }

      // Get auth token
      final token = await StorageService.getSecure('jwt_token');
      if (token == null) {
        return {
          'success': false,
          'message': '⚠️ Authentication required. Please login again.',
        };
      }

      // Step 1: Initialize payment with backend
      final initResponse = await http.post(
        Uri.parse('$baseUrl/wallet/paystack/initialize'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'amount': amount}),
      );

      if (initResponse.statusCode != 200 && initResponse.statusCode != 201) {
        final error = jsonDecode(initResponse.body);
        throw Exception(error['error'] ?? 'Failed to initialize payment');
      }

      final initData = jsonDecode(initResponse.body);

      if (initData['success'] != true) {
        throw Exception(initData['message'] ?? 'Payment initialization failed');
      }

      // Step 2: Get authorization URL from backend response
      final authorizationUrl = initData['authorization_url'];
      final reference = initData['reference'];

      if (authorizationUrl == null || reference == null) {
        throw Exception('No authorization URL received from backend');
      }

      // Step 3: Open Paystack payment page in inline webview
      final paymentCompleted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PaystackPaymentScreen(
            authorizationUrl: authorizationUrl,
            reference: reference,
          ),
          fullscreenDialog: true,
        ),
      );

      // Step 4: Check if payment was completed
      if (paymentCompleted != true) {
        return {
          'success': false,
          'message': '⚠️ Payment cancelled',
        };
      }

      // Step 5: Verify payment with backend
      final verifyResponse = await http.get(
        Uri.parse('$baseUrl/wallet/paystack/verify?reference=$reference'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (verifyResponse.statusCode != 200) {
        throw Exception('Failed to verify payment');
      }

      final verifyData = jsonDecode(verifyResponse.body);

      if (verifyData['success'] == true) {
        return {
          'success': true,
          'message': '✅ Wallet funded successfully!',
          'newBalance': verifyData['newBalance'],
          'transaction': verifyData['transaction'],
        };
      } else {
        return {
          'success': false,
          'message': verifyData['message'] ?? '⚠️ Payment verification failed',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': '🌐 Network error. Please check your internet connection.',
      };
    } catch (e) {
      // Handle specific error messages
      String errorMessage = e.toString();
      
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      
      if (errorMessage.contains('401')) {
        return {
          'success': false,
          'message': '⚠️ Session expired. Please login again.',
        };
      }
      
      if (errorMessage.contains('timeout')) {
        return {
          'success': false,
          'message': '⏱️ Request timeout. Please try again.',
        };
      }

      return {
        'success': false,
        'message': '⚠️ $errorMessage',
      };
    }
  }
}
