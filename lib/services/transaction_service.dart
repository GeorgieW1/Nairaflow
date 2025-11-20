import 'package:nairaflow/models/transaction.dart';
import 'package:nairaflow/models/user.dart';
import 'package:nairaflow/services/api_service.dart';
import 'package:nairaflow/services/storage_service.dart';

class TransactionService {
  // Purchase airtime
  static Future<Transaction> purchaseAirtime({
    required String phone,
    required NetworkProvider network,
    required double amount,
  }) async {
    try {
      final requestData = {
        'phone': phone,
        'network': network.name.toUpperCase(),
        'amount': amount,
      };

      final response = await ApiService.buyAirtime(requestData);
      
      if (response.data['success'] == true) {
        final transactionData = response.data['transaction'] as Map<String, dynamic>;
        final transaction = Transaction.fromJson({
          ...transactionData,
          'userId': await _getCurrentUserId(),
          'type': TransactionType.airtime.name,
          'network': network.name,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Store transaction locally
        await _storeTransaction(transaction);
        
        // Refresh wallet balance from backend
        await _refreshWalletBalance();

        return transaction;
      } else {
        throw Exception(response.data['message'] ?? 'Purchase failed');
      }
    } catch (e) {
      if (e.toString().contains('DioException')) {
        throw Exception('Airtime purchase failed: Unable to connect to server');
      }
      throw Exception('Airtime purchase failed: ${e.toString()}');
    }
  }

  // Purchase data
  static Future<Transaction> purchaseData({
    required String phone,
    required NetworkProvider network,
    required double amount,
    required String dataPackage,
    String? variationCode,  // ← NEW: The critical variation_code!
  }) async {
    try {
      final requestData = {
        'phone': phone,
        'network': network.name.toUpperCase(),
        'dataPlan': dataPackage,
        'amount': amount,
        if (variationCode != null) 'variationCode': variationCode,  // ← Send to backend!
      };

      print('📤 Purchasing data with: $requestData'); // Debug log

      final response = await ApiService.buyData(requestData);
      
      print('📥 Data purchase response: ${response.data}'); // Debug log
      
      if (response.data['success'] == true) {
        final transactionData = response.data['transaction'] as Map<String, dynamic>;
        final transaction = Transaction.fromJson({
          ...transactionData,
          'userId': await _getCurrentUserId(),
          'type': TransactionType.data.name,
          'network': network.name,
          'description': dataPackage,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Store transaction locally
        await _storeTransaction(transaction);
        
        // Refresh wallet balance from backend
        await _refreshWalletBalance();

        return transaction;
      } else {
        final errorMsg = response.data['message'] ?? 'Purchase failed';
        print('❌ Data purchase failed: $errorMsg'); // Debug log
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Data purchase error: $e'); // Debug log
      if (e.toString().contains('DioException')) {
        throw Exception('Unable to connect to server');
      }
      // Clean up error message
      final errorMsg = e.toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Data purchase failed: ', '');
      throw Exception(errorMsg);
    }
  }

  // Pay electricity bill
  static Future<Transaction> payElectricity({
    required String meterNumber,
    required double amount,
    required String disco, // Distribution company
    required String meterType, // prepaid or postpaid
  }) async {
    try {
      final requestData = {
        'meterNumber': meterNumber,
        'meterType': meterType.toLowerCase(),
        'provider': disco,
        'amount': amount,
      };

      final response = await ApiService.payElectricity(requestData);
      
      if (response.data['success'] == true) {
        final transactionData = response.data['transaction'] as Map<String, dynamic>;
        final transaction = Transaction.fromJson({
          ...transactionData,
          'userId': await _getCurrentUserId(),
          'type': TransactionType.electricity.name,
          'phone': meterNumber,
          'description': '$disco - ₦${amount.toStringAsFixed(2)}',
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Store transaction locally
        await _storeTransaction(transaction);
        
        // Refresh wallet balance from backend
        await _refreshWalletBalance();

        return transaction;
      } else {
        throw Exception(response.data['message'] ?? 'Payment failed');
      }
    } catch (e) {
      if (e.toString().contains('DioException')) {
        throw Exception('Electricity payment failed: Unable to connect to server');
      }
      throw Exception('Electricity payment failed: ${e.toString()}');
    }
  }

  // Fund wallet
  static Future<Transaction> fundWallet({
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final requestData = {
        'amount': amount,
        'paymentMethod': paymentMethod,
      };

      final response = await ApiService.fundWallet(requestData);
      
      if (response.data['success'] == true) {
        final transactionData = response.data['transaction'] as Map<String, dynamic>;
        final transaction = Transaction.fromJson({
          ...transactionData,
          'userId': await _getCurrentUserId(),
          'type': TransactionType.funding.name,
          'description': 'Wallet funding via $paymentMethod',
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Store transaction locally
        await _storeTransaction(transaction);
        
        // Refresh wallet balance from backend
        await _refreshWalletBalance();

        return transaction;
      } else {
        throw Exception(response.data['message'] ?? 'Funding failed');
      }
    } catch (e) {
      if (e.toString().contains('DioException')) {
        throw Exception('Wallet funding failed: Unable to connect to server');
      }
      throw Exception('Wallet funding failed: ${e.toString()}');
    }
  }

  // Get transaction history
  static Future<List<Transaction>> getTransactionHistory() async {
    try {
      // Check if user has a token before making API call
      final token = await StorageService.getSecure('jwt_token');
      if (token == null) {
        // No token, return cached transactions or empty list
        return await _getLocalTransactions();
      }
      
      final response = await ApiService.getTransactions(limit: 100);
      final userId = await _getCurrentUserId();
      
      if (response.data['success'] == true) {
        final transactionsData = response.data['transactions'] as List;
        final transactions = transactionsData
            .map((t) => Transaction.fromJson({
              ...t,
              'userId': t['userId'] ?? t['user']?['_id'] ?? userId,
            }))
            .toList();
        
        // Cache transactions locally
        await StorageService.storeList(
          'transactions',
          transactions.map((t) => t.toJson()).toList(),
        );
        
        return transactions..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      // Fallback to local storage if API fails
      return await _getLocalTransactions();
    } catch (e) {
      // Return cached transactions if API fails
      return await _getLocalTransactions();
    }
  }

  static Future<List<Transaction>> _getLocalTransactions() async {
    try {
      final transactions = await StorageService.getList('transactions');
      final userId = await _getCurrentUserId();
      
      return transactions
          .where((t) => t['userId'] == userId)
          .map((t) => Transaction.fromJson(t))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  // Get recent transactions (last 5)
  static Future<List<Transaction>> getRecentTransactions() async {
    final allTransactions = await getTransactionHistory();
    return allTransactions.take(5).toList();
  }

  // Private helper methods
  static Future<String> _getCurrentUserId() async {
    final userData = await StorageService.getJson('user_data');
    return userData?['id'] ?? '';
  }

  static Future<void> _storeTransaction(Transaction transaction) async {
    final existingTransactions = await StorageService.getList('transactions');
    existingTransactions.add(transaction.toJson());
    await StorageService.storeList('transactions', existingTransactions);
  }

  static Future<void> _refreshWalletBalance() async {
    try {
      final response = await ApiService.getWalletBalance();
      
      if (response.data['success'] == true) {
        final balance = (response.data['balance'] as num).toDouble();
        
        // Update local user data with new balance
        final userData = await StorageService.getJson('user_data');
        if (userData != null) {
          final currentUser = User.fromJson(userData);
          final updatedUser = currentUser.copyWith(
            walletBalance: balance,
            updatedAt: DateTime.now(),
          );
          await StorageService.storeJson('user_data', updatedUser.toJson());
        }
      }
    } catch (e) {
      print('Error refreshing wallet balance: $e');
    }
  }

  // Initialize with sample data for demo
  static Future<void> initializeSampleData() async {
    final existingTransactions = await StorageService.getList('transactions');
    if (existingTransactions.isNotEmpty) return; // Already initialized
    
    final userId = await _getCurrentUserId();
    if (userId.isEmpty) return;

    final sampleTransactions = [
      Transaction(
        id: '1',
        userId: userId,
        type: TransactionType.airtime,
        amount: 200.0,
        phone: '08012345678',
        network: NetworkProvider.mtn,
        status: TransactionStatus.success,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Transaction(
        id: '2',
        userId: userId,
        type: TransactionType.data,
        amount: 1500.0,
        phone: '08012345678',
        network: NetworkProvider.airtel,
        description: '5GB Data Bundle',
        status: TransactionStatus.success,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Transaction(
        id: '3',
        userId: userId,
        type: TransactionType.funding,
        amount: 5000.0,
        description: 'Wallet funding via Bank Transfer',
        status: TransactionStatus.success,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Transaction(
        id: '4',
        userId: userId,
        type: TransactionType.electricity,
        amount: 3000.0,
        phone: '12345678901',
        description: 'IKEDC - ₦3000.00',
        status: TransactionStatus.success,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];

    await StorageService.storeList(
      'transactions',
      sampleTransactions.map((t) => t.toJson()).toList(),
    );
  }
}