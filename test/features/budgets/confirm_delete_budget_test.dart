import 'package:dio/dio.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/presentation/helpers/confirm_delete_budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every deleteBudget call so the test can assert (or assert absence).
class _FakeBudgetRepository extends BudgetRepository {
  _FakeBudgetRepository() : super(Dio());

  final List<String> deletedIds = <String>[];

  @override
  Future<void> deleteBudget(String id) async {
    deletedIds.add(id);
  }
}

Budget _budget(String id, {String category = 'Mercado'}) => Budget(
  id: id,
  userId: 'user-1',
  category: category,
  limitAmount: 100000,
  period: 'monthly',
);

void main() {
  /// Pumps a host that exposes a button which invokes [confirmDeleteBudget]
  /// with the given target, and counts how many times [target] is rebuilt.
  Future<int Function()> pumpHost(
    WidgetTester tester, {
    required _FakeBudgetRepository repo,
    required Budget budget,
    required ProviderOrFamily invalidateTarget,
    required FutureProvider<List<Budget>> listProbe,
  }) async {
    var listFetches = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetRepositoryProvider.overrideWithValue(repo),
          listProbe.overrideWith((ref) async {
            listFetches++;
            return [budget];
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                // Watch the probe so an invalidate forces a recompute.
                ref.watch(listProbe);
                return ElevatedButton(
                  onPressed: () => confirmDeleteBudget(
                    context,
                    ref,
                    budget,
                    invalidateTarget: invalidateTarget,
                  ),
                  child: const Text('borrar'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => listFetches;
  }

  testWidgets(
    'Personal: confirmar borrado llama deleteBudget e invalida budgetsListProvider(null)',
    (tester) async {
      final repo = _FakeBudgetRepository();
      final budget = _budget('goal-personal');
      final probe = budgetsListProvider(null);

      final fetches = await pumpHost(
        tester,
        repo: repo,
        budget: budget,
        invalidateTarget: probe,
        listProbe: probe,
      );
      final fetchesBefore = fetches();

      await tester.tap(find.text('borrar'));
      await tester.pumpAndSettle();

      // Confirm the deletion in the dialog.
      expect(find.text('Eliminar Meta'), findsOneWidget);
      expect(find.textContaining('no se puede deshacer'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(repo.deletedIds, ['goal-personal']);
      expect(
        fetches(),
        greaterThan(fetchesBefore),
        reason: 'budgetsListProvider(null) invalidated after delete',
      );
    },
  );

  testWidgets(
    'Cancelar borrado NUNCA llama deleteBudget y no invalida la lista',
    (tester) async {
      final repo = _FakeBudgetRepository();
      final budget = _budget('goal-keep');
      final probe = budgetsListProvider(null);

      final fetches = await pumpHost(
        tester,
        repo: repo,
        budget: budget,
        invalidateTarget: probe,
        listProbe: probe,
      );
      final fetchesBefore = fetches();

      await tester.tap(find.text('borrar'));
      await tester.pumpAndSettle();

      // Cancel the deletion.
      expect(find.text('Eliminar Meta'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.deletedIds, isEmpty, reason: 'cancel must not delete');
      expect(
        fetches(),
        fetchesBefore,
        reason: 'cancel must not invalidate the list',
      );
    },
  );

  testWidgets(
    'Hogar: confirmar borrado llama deleteBudget e invalida budgetsListProvider(householdId)',
    (tester) async {
      const householdId = 'house-9';
      final repo = _FakeBudgetRepository();
      final budget = _budget('goal-household');
      final probe = budgetsListProvider(householdId);

      final fetches = await pumpHost(
        tester,
        repo: repo,
        budget: budget,
        invalidateTarget: probe,
        listProbe: probe,
      );
      final fetchesBefore = fetches();

      await tester.tap(find.text('borrar'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(repo.deletedIds, ['goal-household']);
      expect(
        fetches(),
        greaterThan(fetchesBefore),
        reason: 'budgetsListProvider(householdId) invalidated after delete',
      );
    },
  );
}
