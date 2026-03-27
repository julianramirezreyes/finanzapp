import 'package:finanzapp_v2/features/accounts/data/account_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountsListProvider = FutureProvider.autoDispose<List<Account>>((
  ref,
) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getAccounts();
});

// Provider para obtener el resumen de deuda de una cuenta
final debtSummaryProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, accountId) async {
    final repository = ref.watch(accountRepositoryProvider);
    return repository.getDebtSummary(accountId);
  },
);
