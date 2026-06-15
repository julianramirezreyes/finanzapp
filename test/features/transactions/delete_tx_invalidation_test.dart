import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/config/backend_config_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:finanzapp_v2/features/history/data/history_provider.dart';
import 'package:finanzapp_v2/features/history/domain/personal_history_summary.dart';
import 'package:finanzapp_v2/features/household/presentation/household_history_screen.dart';
import 'package:finanzapp_v2/features/transactions/presentation/transactions_screen.dart';
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
    Account(id: id, name: name, type: 'cash', balance: 100000, currency: 'COP');

Map<String, dynamic> _txJson(String id) => <String, dynamic>{
      'id': id,
      'account_id': 'acc-1',
      'amount': 1000.0,
      'type': 'expense',
      'category': 'food',
      'description': 'Almuerzo',
      'date': '2026-06-10T00:00:00.000Z',
      'context': 'personal',
      'user_id': 'u-1',
    };

PersonalHistorySummary _summaryWith(List<Map<String, dynamic>> txs) =>
    PersonalHistorySummary(
      totalIncome: 0,
      totalExpense: 1000,
      expensePersonal: 1000,
      expenseHousehold: 0,
      movements: 1,
      balance: -1000,
      count: txs.length,
      transactions: txs,
    );

void main() {
  setUp(() async {
    // TransactionsScreen formats the month header with DateFormat.yMMMM('es_CO').
    await initializeDateFormatting('es_CO');
  });

  testWidgets(
    '5a.1: deleting a transaction invalidates the FULL effect set '
    '(dashboard, budgets, householdSnapshot, vaultDebtSummary, creditCardsWithDebt) '
    'in addition to history/transactions/accounts',
    (tester) async {
      final now = DateTime.now();
      final historyArgs = (month: now.month, year: now.year);
      const snapshotArgs = (householdId: 'hh-1', year: 2026, month: 6);
      const debtArg = 'acc-1';

      final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
      final dio = buildFakeDio(adapter);

      var dashboardFetches = 0;
      var budgetsFetches = 0;
      var snapshotFetches = 0;
      var debtFetches = 0;
      var cardsFetches = 0;
      var historyFetches = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWith(() => _FixedDioNotifier(dio)),
            accountsListProvider.overrideWith(
              (ref) async => [_account('acc-1', 'Efectivo')],
            ),
            personalHistoryProvider(historyArgs).overrideWith((ref) async {
              historyFetches++;
              return _summaryWith([_txJson('tx-1')]);
            }),
            dashboardProvider.overrideWith((ref) async {
              dashboardFetches++;
              return _emptyDashboard();
            }),
            budgetsListProvider(null).overrideWith((ref) async {
              budgetsFetches++;
              return <Budget>[];
            }),
            householdSnapshotProvider(snapshotArgs).overrideWith((ref) async {
              snapshotFetches++;
              return <String, dynamic>{};
            }),
            vaultDebtSummaryProvider(debtArg).overrideWith((ref) async {
              debtFetches++;
              return <Map<String, dynamic>>[];
            }),
            creditCardsWithDebtProvider.overrideWith((ref) async {
              cardsFetches++;
              return <Map<String, dynamic>>[];
            }),
          ],
          child: const MaterialApp(home: TransactionsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // The screen does not watch the debt/budget/snapshot providers, so prime
      // them via the container and keep them alive (defeat autoDispose) so the
      // ONLY thing that recomputes them is the delete handler's invalidate.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TransactionsScreen)),
      );
      container.listen(dashboardProvider, (_, _) {});
      container.listen(budgetsListProvider(null), (_, _) {});
      container.listen(householdSnapshotProvider(snapshotArgs), (_, _) {});
      container.listen(vaultDebtSummaryProvider(debtArg), (_, _) {});
      container.listen(creditCardsWithDebtProvider, (_, _) {});
      await tester.runAsync(() async {
        await container.read(dashboardProvider.future);
        await container.read(budgetsListProvider(null).future);
        await container.read(householdSnapshotProvider(snapshotArgs).future);
        await container.read(vaultDebtSummaryProvider(debtArg).future);
        await container.read(creditCardsWithDebtProvider.future);
      });

      expect(dashboardFetches, 1, reason: 'primed once');
      expect(historyFetches, greaterThanOrEqualTo(1));
      final historyBefore = historyFetches;

      // Open the row menu and pick Eliminar.
      await tester.ensureVisible(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert).first, warnIfMissed: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      // Confirm in the DeleteConfirmDialog.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar'));
      await tester.pumpAndSettle();

      // The DELETE must have been issued.
      final deletes = adapter.requests.where((r) => r.method == 'DELETE');
      expect(deletes, isNotEmpty, reason: 'delete request issued');

      // The full effect set must be invalidated → recomputed.
      expect(dashboardFetches, greaterThan(1), reason: 'dashboard stale today');
      expect(budgetsFetches, greaterThan(1), reason: 'budgets stale today');
      expect(snapshotFetches, greaterThan(1), reason: 'householdSnapshot stale today');
      expect(debtFetches, greaterThan(1), reason: 'vaultDebtSummary stale today');
      expect(cardsFetches, greaterThan(1), reason: 'creditCardsWithDebt stale today');
      // history is still invalidated (already worked before the fix).
      expect(historyFetches, greaterThan(historyBefore),
          reason: 'personalHistory still invalidated');
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
