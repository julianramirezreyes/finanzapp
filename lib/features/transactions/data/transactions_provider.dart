import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionsListProvider = FutureProvider.autoDispose<List<Transaction>>((
  ref,
) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactions();
});
