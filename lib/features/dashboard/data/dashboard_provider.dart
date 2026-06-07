import 'package:finanzapp_v2/features/accounts/data/account_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/pocket_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/accounts/domain/pocket.dart';
import 'package:finanzapp_v2/features/history/data/history_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardData {
  final double totalBalance;
  final double yearlyIncome;
  final double yearlyExpense;
  final List<Account> accounts;
  final Map<String, double> pocketsTotals;
  final Map<String, int> pocketsCounts;

  DashboardData({
    required this.totalBalance,
    required this.yearlyIncome,
    required this.yearlyExpense,
    required this.accounts,
    required this.pocketsTotals,
    required this.pocketsCounts,
  });

  double get yearlyBalance => yearlyIncome - yearlyExpense;
  double get totalBalanceWithPockets =>
      totalBalance + pocketsTotals.values.fold(0.0, (sum, v) => sum + v);
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((
  ref,
) async {
  final accountRepo = ref.watch(accountRepositoryProvider);
  final pocketRepo = ref.watch(pocketRepositoryProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);

  // PARALLEL LOADING: Load accounts and history in parallel
  final accountsFuture = accountRepo.getAccounts();
  final historyFuture = historyRepo.getYearlySummary();

  // Wait for both to complete
  final accounts = await accountsFuture;
  final yearlySummary = await historyFuture;
  // Net worth excludes accounts the user flagged out (e.g. shared/credit cards).
  final totalBalance = accounts
      .where((acc) => acc.includeInNetWorth)
      .fold(0.0, (sum, acc) => sum + acc.balance);

  // Fetch all pockets in parallel
  final pocketResults = await Future.wait(
    accounts.map(
      (acc) => pocketRepo.getPockets(acc.id).then((pockets) {
        return MapEntry(acc.id, pockets);
      }),
    ),
  ).catchError((_) => <MapEntry<String, List<Pocket>>>[]);

  final pocketsTotals = <String, double>{};
  final pocketsCounts = <String, int>{};
  for (final entry in pocketResults) {
    if (entry.value.isNotEmpty) {
      pocketsTotals[entry.key] = entry.value.fold(
        0.0,
        (sum, p) => sum + p.balance,
      );
      pocketsCounts[entry.key] = entry.value.length;
    }
  }

  return DashboardData(
    totalBalance: totalBalance,
    yearlyIncome: yearlySummary.totalIncome,
    yearlyExpense: yearlySummary.totalExpense,
    accounts: accounts,
    pocketsTotals: pocketsTotals,
    pocketsCounts: pocketsCounts,
  );
});
