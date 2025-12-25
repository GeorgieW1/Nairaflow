import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import 'auth_provider.dart';

class TransactionState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final Ref ref;

  TransactionNotifier(this.ref) : super(const TransactionState());

  Future<void> loadTransactions() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    state = const TransactionState(isLoading: true);

    try {
      final txs = await TransactionService.getTransactionHistory(
        auth.token!,
      );
      state = TransactionState(transactions: txs);
    } catch (e) {
      state = TransactionState(error: e.toString());
    }
  }

  Future<void> fundWallet(double amount, String method) async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    state = const TransactionState(isLoading: true);

    try {
      final tx = await TransactionService.fundWallet(
        token: auth.token!,
        amount: amount,
        paymentMethod: method,
      );

      state = TransactionState(
        transactions: [tx, ...state.transactions],
      );

      await ref.read(authProvider.notifier).refreshUser();
    } catch (e) {
      state = TransactionState(error: e.toString());
    }
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>(
        (ref) => TransactionNotifier(ref));
