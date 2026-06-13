import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/presentation/budget_history_screen.dart';
import 'package:finanzapp_v2/features/transactions/data/transactions_provider.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:finanzapp_v2/shared/ui/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

Budget _budget(String id) => Budget(
  id: id,
  userId: 'user-1',
  category: 'Mercado',
  limitAmount: 100000,
  period: 'monthly',
  isRecurrent: true,
);

Transaction _tx(String id) => Transaction(
  id: id,
  accountId: 'acc-1',
  amount: 12000,
  type: 'expense',
  category: 'Mercado',
  description: 'Compra $id',
  date: DateTime.utc(2026, 6, 10),
  context: 'personal',
  userId: 'user-1',
  budgetId: 'goal-1',
);

void main() {
  setUpAll(() async {
    // TransactionTile formats dates with the es_CO locale.
    await initializeDateFormatting('es_CO');
  });

  /// Builds a router whose start screen is the budget history, plus a stub
  /// edit route that records the [extra] it received and pops on demand.
  ({GoRouter router, List<Object?> capturedExtras}) buildRouter(Budget budget) {
    final capturedExtras = <Object?>[];
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BudgetHistoryScreen(budget: budget),
        ),
        GoRoute(
          path: '/transactions/add',
          builder: (context, state) {
            capturedExtras.add(state.extra);
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('volver'),
                ),
              ),
            );
          },
        ),
      ],
    );
    return (router: router, capturedExtras: capturedExtras);
  }

  testWidgets(
    'tap en un movimiento navega a /transactions/add con extra == la Transaction '
    'y al volver invalida budgetTransactionsProvider(budget.id)',
    (tester) async {
      final budget = _budget('goal-1');
      final tx = _tx('tx-1');
      final built = buildRouter(budget);

      var historyFetches = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            budgetTransactionsProvider(budget.id).overrideWith((ref) async {
              historyFetches++;
              return [tx];
            }),
          ],
          child: MaterialApp.router(routerConfig: built.router),
        ),
      );
      await tester.pumpAndSettle();

      expect(historyFetches, 1, reason: 'initial history load');

      await tester.tap(find.byType(TransactionTile));
      await tester.pumpAndSettle();

      // Navigated to the edit route with the full Transaction as extra.
      expect(built.capturedExtras, hasLength(1));
      expect(built.capturedExtras.single, same(tx));

      // Return to the history screen → provider must be invalidated → refetched.
      await tester.tap(find.widgetWithText(ElevatedButton, 'volver'));
      await tester.pumpAndSettle();

      expect(
        historyFetches,
        greaterThan(1),
        reason: 'history invalidated after returning from edit',
      );
    },
  );

  testWidgets(
    'el TransactionTile del historial NO expone menu de tres puntos '
    '(unica accion es onTap)',
    (tester) async {
      final budget = _budget('goal-1');
      final tx = _tx('tx-1');
      final built = buildRouter(budget);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            budgetTransactionsProvider(budget.id).overrideWith(
              (ref) async => [tx],
            ),
          ],
          child: MaterialApp.router(routerConfig: built.router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransactionTile), findsOneWidget);
      // No three-dots / overflow menu per row.
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    },
  );
}
