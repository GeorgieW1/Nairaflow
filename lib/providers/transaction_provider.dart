import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nairaflow/models/transaction.dart';
import 'package:nairaflow/services/transaction_service.dart';
import 'package:nairaflow/services/paystack_service.dart';
import 'package:nairaflow/providers/auth_provider.dart';

// Transaction state
class TransactionState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<Transaction> get recentTransactions => transactions.take(5).toList();
}

// Transaction provider
class TransactionNotifier extends StateNotifier<TransactionState> {
  final Ref ref;

  TransactionNotifier(this.ref) : super(const TransactionState()) {
    // Listen to auth changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Clear transactions when user logs out
      if (previous?.user != null && next.user == null) {
        state = const TransactionState();
      }
      // Load transactions when user logs in
      else if (previous?.user == null && next.user != null) {
        loadTransactions();
      }
    });
    
    // Only load transactions on init if user is authenticated
    if (ref.read(authProvider).isAuthenticated) {
      loadTransactions();
    }
  }

  Future<void> loadTransactions() async {
    // Don't load transactions if user is not authenticated
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = state.copyWith(transactions: [], isLoading: false, error: null);
      return;
    }
    
    state = state.copyWith(isLoading: true);
    try {
      final transactions = await TransactionService.getTransactionHistory();
      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> purchaseAirtime({
    required String phone,
    required NetworkProvider network,
    required double amount,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transaction = await TransactionService.purchaseAirtime(
        phone: phone,
        network: network,
        amount: amount,
      );
      
      state = state.copyWith(
        transactions: [transaction, ...state.transactions],
        isLoading: false,
        error: null,
      );
      
      // Refresh user data to get updated wallet balance
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> purchaseData({
    required String phone,
    required NetworkProvider network,
    required double amount,
    required String dataPackage,
    String? variationCode,  // ← NEW: Pass variation_code
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transaction = await TransactionService.purchaseData(
        phone: phone,
        network: network,
        amount: amount,
        dataPackage: dataPackage,
        variationCode: variationCode,  // ← Pass to service
      );
      
      state = state.copyWith(
        transactions: [transaction, ...state.transactions],
        isLoading: false,
        error: null,
      );
      
      // Refresh user data to get updated wallet balance
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> payElectricity({
    required String meterNumber,
    required double amount,
    required String disco,
    required String meterType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transaction = await TransactionService.payElectricity(
        meterNumber: meterNumber,
        amount: amount,
        disco: disco,
        meterType: meterType,
      );
      
      state = state.copyWith(
        transactions: [transaction, ...state.transactions],
        isLoading: false,
        error: null,
      );
      
      // Refresh user data to get updated wallet balance
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Paystack wallet funding (with all payment methods)
  Future<Map<String, dynamic>> fundWalletWithPaystack({
    required BuildContext context,
    required double amount,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get user email from auth provider
      final user = ref.read(authProvider).user;
      final userEmail = user?.email ?? '';

      if (userEmail.isEmpty) {
        state = state.copyWith(isLoading: false, error: '⚠️ Email is required for payment.');
        return {
          'success': false,
          'message': '⚠️ Email is required for payment.',
        };
      }

      // Call Paystack service
      final result = await PaystackService.fundWallet(
        context: context,
        amount: amount,
        userEmail: userEmail,
        paymentMethod: paymentMethod,
      );

      if (result['success'] == true) {
        // Reload transactions to get the new funding transaction
        await loadTransactions();
        
        // Refresh user data to get updated wallet balance
        await ref.read(authProvider.notifier).refreshUser();
        
        state = state.copyWith(isLoading: false, error: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? '⚠️ Payment failed',
        );
      }

      return result;
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Demo wallet funding (backward compatibility)
  Future<void> fundWallet({
    required double amount,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transaction = await TransactionService.fundWallet(
        amount: amount,
        paymentMethod: paymentMethod,
      );
      
      state = state.copyWith(
        transactions: [transaction, ...state.transactions],
        isLoading: false,
        error: null,
      );
      
      // Refresh user data to get updated wallet balance
      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref);
});

// Recent transactions provider
final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactionState = ref.watch(transactionProvider);
  return transactionState.recentTransactions;
});