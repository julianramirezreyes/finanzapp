import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionsListProvider = FutureProvider.autoDispose<List<Transaction>>((
  ref,
) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactions();
});

/// Transactions linked to a specific budget/goal — powers the per-goal history.
final budgetTransactionsProvider = FutureProvider.autoDispose
    .family<List<Transaction>, String>((ref, budgetId) async {
      final repository = ref.watch(transactionRepositoryProvider);
      return repository.getTransactions(budgetId: budgetId, limit: 200);
    });
