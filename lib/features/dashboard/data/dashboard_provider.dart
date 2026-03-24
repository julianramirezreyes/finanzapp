import 'package:finanzapp_v2/features/accounts/data/account_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/history/data/history_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardData {
  final double totalBalance;
  final double yearlyIncome;
  final double yearlyExpense;
  final List<Account> accounts;

  DashboardData({
    required this.totalBalance,
    required this.yearlyIncome,
    required this.yearlyExpense,
    required this.accounts,
  });

  double get yearlyBalance => yearlyIncome - yearlyExpense;
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((
  ref,
) async {
  final accountRepo = ref.watch(accountRepositoryProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);

  final accounts = await accountRepo.getAccounts();
  final totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);

  final yearlySummary = await historyRepo.getYearlySummary();

  return DashboardData(
    totalBalance: totalBalance,
    yearlyIncome: yearlySummary.totalIncome,
    yearlyExpense: yearlySummary.totalExpense,
    accounts: accounts,
  );
});
