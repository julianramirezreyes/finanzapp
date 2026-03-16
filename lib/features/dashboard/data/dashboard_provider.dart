import 'package:finanzapp_v2/features/accounts/data/account_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
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
  final transactionRepo = ref.watch(transactionRepositoryProvider);

  // 1. Fetch Accounts for Total Balance
  final accounts = await accountRepo.getAccounts();
  final totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);

  // 2. Fetch Transactions for Current Year (YTD)
  final now = DateTime.now();
  final startOfYear = DateTime(now.year, 1, 1);
  final endOfNow = now;

  final transactions = await transactionRepo.getTransactions(
    startDate: startOfYear,
    endDate: endOfNow,
    limit: 1000, // Fetch all for accurate summary
  );

  double income = 0;
  double expense = 0;

  for (var tx in transactions) {
    if (tx.type == 'income') {
      income += tx.amount;
    } else if (tx.type == 'expense') {
      expense += tx.amount;
    }
    // Transfers shouldn't affect "Net" Income/Expense global summary usually,
    // or checks context? For personal summary, maybe.
    // Logic from v1:
    // if (mov['type'] == 'Ingreso') ingresos += ...
    // if (mov['type'] == 'Gasto') gastos += ...
  }

  return DashboardData(
    totalBalance: totalBalance,
    yearlyIncome: income,
    yearlyExpense: expense,
    accounts: accounts,
  );
});
