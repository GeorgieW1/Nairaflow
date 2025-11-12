import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nairaflow/models/transaction.dart';
import 'package:nairaflow/services/transaction_service.dart';
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
    loadTransactions();
  }

  Future<void> loadTransactions() async {
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
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transaction = await TransactionService.purchaseData(
        phone: phone,
        network: network,
        amount: amount,
        dataPackage: dataPackage,
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