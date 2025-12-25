import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class TransactionService {
  static const baseUrl =
      'https://api.nairapay.ng/api/v1/transactions';

  static Map<String, String> headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<List<Transaction>> getTransactionHistory(String token) async {
    final res = await http.get(
      Uri.parse(baseUrl),
      headers: headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load transactions');
    }

    final data = json.decode(res.body);
    return (data['transactions'] as List)
        .map((e) => Transaction.fromJson(e))
        .toList();
  }

  static Future<Transaction> fundWallet({
    required String token,
    required double amount,
    required String paymentMethod,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/fund'),
      headers: headers(token),
      body: json.encode({
        'amount': amount,
        'paymentMethod': paymentMethod,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Wallet funding failed');
    }

    return Transaction.fromJson(json.decode(res.body)['transaction']);
  }
}
