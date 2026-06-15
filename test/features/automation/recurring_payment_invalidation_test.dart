import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/config/backend_config_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/automation/data/automation_repository.dart';
import 'package:finanzapp_v2/features/automation/domain/recurring_payment.dart';
import 'package:finanzapp_v2/features/automation/presentation/recurring_payments_screen.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:finanzapp_v2/features/history/data/history_provider.dart';
import 'package:finanzapp_v2/features/history/domain/personal_history_summary.dart';
import 'package:finanzapp_v2/features/household/presentation/household_history_screen.dart';
import 'package:finanzapp_v2/features/transactions/data/transactions_provider.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fake_dio_adapter.dart';

class _FixedDioNotifier extends DioClientNotifier {
  _FixedDioNotifier(this._dio);
  final Dio _dio;
  @override
  Dio build() => _dio;
}

Account _account(String id, String name) =>
    Account(id: id, name: name, type: 'cash', balance: 500000, currency: 'COP');

RecurringPayment _duePayment(String id) => RecurringPayment(
      id: id,
      accountId: 'acc-1',
      context: 'personal',
      category: 'Servicios',
      description: 'Internet',
      amount: 80000,
      frequency: 'monthly',
      startDate: DateTime.utc(2026, 1, 1),
      // In the past so the row exposes the "Ejecutar" action (isDue == true).
      nextExecutionDate: DateTime.utc(2020, 1, 1),
      isAutoConfirm: false,
      isActive: true,
    );

void main() {
  setUp(() async {
    await initializeDateFormatting('es_CO');
  });

  testWidgets(
    '5a.3: executing a recurring payment invalidates the tx effect set '
    '(dashboard, accounts, transactions, history, budgets, householdSnapshot) '
    'in addition to the pending/all-recurring lists',
    (tester) async {
      final historyArgs = (month: DateTime.now().month, year: DateTime.now().year);
      const snapshotArgs = (householdId: 'hh-1', year: 2026, month: 6);

      final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
      final dio = buildFakeDio(adapter);

      var dashboardFetches = 0;
      var accountsFetches = 0;
      var txFetches = 0;
      var historyFetches = 0;
      var budgetsFetches = 0;
      var snapshotFetches = 0;
      var pendingFetches = 0;
      var allRecurringFetches = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWith(() => _FixedDioNotifier(dio)),
            allRecurringPaymentsProvider.overrideWith((ref) async {
              allRecurringFetches++;
              return [_duePayment('rp-1')];
            }),
            pendingPaymentsProvider.overrideWith((ref) async {
              pendingFetches++;
              return <RecurringPayment>[];
            }),
            accountsListProvider.overrideWith((ref) async {
              accountsFetches++;
              return [_account('acc-1', 'Efectivo')];
            }),
            dashboardProvider.overrideWith((ref) async {
              dashboardFetches++;
              return _emptyDashboard();
            }),
            transactionsListProvider.overrideWith((ref) async {
              txFetches++;
              return <Transaction>[];
            }),
            personalHistoryProvider(historyArgs).overrideWith((ref) async {
              historyFetches++;
              return _emptyHistory();
            }),
            budgetsListProvider(null).overrideWith((ref) async {
              budgetsFetches++;
              return <Budget>[];
            }),
            householdSnapshotProvider(snapshotArgs).overrideWith((ref) async {
              snapshotFetches++;
              return <String, dynamic>{};
            }),
          ],
          child: const MaterialApp(home: RecurringPaymentsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // The screen watches allRecurring + accounts; prime + keep alive the rest.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RecurringPaymentsScreen)),
      );
      container.listen(dashboardProvider, (_, _) {});
      container.listen(transactionsListProvider, (_, _) {});
      container.listen(personalHistoryProvider(historyArgs), (_, _) {});
      container.listen(budgetsListProvider(null), (_, _) {});
      container.listen(householdSnapshotProvider(snapshotArgs), (_, _) {});
      container.listen(pendingPaymentsProvider, (_, _) {});
      await tester.runAsync(() async {
        await container.read(dashboardProvider.future);
        await container.read(transactionsListProvider.future);
        await container.read(personalHistoryProvider(historyArgs).future);
        await container.read(budgetsListProvider(null).future);
        await container.read(householdSnapshotProvider(snapshotArgs).future);
        await container.read(pendingPaymentsProvider.future);
      });

      expect(dashboardFetches, 1, reason: 'primed once');
      final accountsBefore = accountsFetches;
      final allRecurringBefore = allRecurringFetches;
      final pendingBefore = pendingFetches;

      // Open the row menu, pick Ejecutar, then confirm in the dialog.
      await tester.ensureVisible(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Ejecutar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Ejecutar'));
      await tester.pumpAndSettle();

      // The execute call must have been issued.
      final posts = adapter.requests.where(
        (r) => r.method == 'POST' && r.path.contains('/automation/execute/'),
      );
      expect(posts, isNotEmpty, reason: 'execute payment issued');

      // The full tx effect set must be invalidated → recomputed.
      expect(dashboardFetches, greaterThan(1), reason: 'dashboard stale today');
      expect(accountsFetches, greaterThan(accountsBefore),
          reason: 'accounts stale today');
      expect(txFetches, greaterThan(1), reason: 'transactions stale today');
      expect(historyFetches, greaterThan(1), reason: 'history stale today');
      expect(budgetsFetches, greaterThan(1), reason: 'budgets stale today');
      expect(snapshotFetches, greaterThan(1), reason: 'snapshot stale today');

      // The pre-existing automation invalidations must still happen.
      expect(allRecurringFetches, greaterThan(allRecurringBefore),
          reason: 'allRecurringPayments still invalidated');
      expect(pendingFetches, greaterThan(pendingBefore),
          reason: 'pendingPayments still invalidated');
    },
  );
}

DashboardData _emptyDashboard() => DashboardData(
      totalBalance: 0,
      yearlyIncome: 0,
      yearlyExpense: 0,
      accounts: const <Account>[],
      pocketsTotals: const <String, double>{},
      pocketsCounts: const <String, int>{},
    );

PersonalHistorySummary _emptyHistory() => PersonalHistorySummary(
      totalIncome: 0,
      totalExpense: 0,
      expensePersonal: 0,
      expenseHousehold: 0,
      movements: 0,
      balance: 0,
      count: 0,
      transactions: const <dynamic>[],
    );
