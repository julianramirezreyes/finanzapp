import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final householdTransactionsProvider = FutureProvider.family
    .autoDispose<List<Transaction>, String>((ref, householdId) async {
      final repository = ref.watch(transactionRepositoryProvider);
      return repository.getHouseholdTransactions(householdId);
    });
