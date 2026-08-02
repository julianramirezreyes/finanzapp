import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/config/backend_config_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/presentation/reorder_budgets_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

class _FixedDioNotifier extends DioClientNotifier {
  _FixedDioNotifier(this._dio);

  final Dio _dio;

  @override
  Dio build() => _dio;
}

Budget _budget(String id, int displayOrder) => Budget(
  id: id,
  userId: 'user-1',
  category: 'Goal $id',
  limitAmount: 100000,
  period: 'monthly',
  displayOrder: displayOrder,
);

Future<({WidgetRef ref, BuildContext context, ProviderContainer container})>
_mount(WidgetTester tester, List<Override> overrides) async {
  late WidgetRef capturedRef;
  late BuildContext capturedContext;
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              capturedContext = context;
              container = ProviderScope.containerOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  return (ref: capturedRef, context: capturedContext, container: container);
}

void main() {
  test(
    'reorder payload keeps immutable server expected_order values with the new order',
    () async {
      final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
      final repository = BudgetRepository(buildFakeDio(adapter));
      final orderedAfterDrag = [_budget('goal-2', 1), _budget('goal-1', 0)];

      await repository.reorderBudgets(orderedAfterDrag);

      final body = adapter.lastRequest.body as List<dynamic>;
      expect(body, [
        {'id': 'goal-2', 'order': 0, 'expected_order': 1},
        {'id': 'goal-1', 'order': 1, 'expected_order': 0},
      ]);
    },
  );

  testWidgets(
    'reorder adjusts the downward index and refreshes the confirmed personal list',
    (tester) async {
      var fetches = 0;
      final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
      final budgets = [_budget('goal-1', 0), _budget('goal-2', 1)];
      final h = await _mount(tester, [
        dioProvider.overrideWith(
          () => _FixedDioNotifier(buildFakeDio(adapter)),
        ),
        budgetsListProvider(null).overrideWith((ref) async {
          fetches++;
          return budgets;
        }),
      ]);
      h.container.listen(budgetsListProvider(null), (_, _) {});
      await tester.runAsync(
        () => h.container.read(budgetsListProvider(null).future),
      );
      List<Budget>? optimistic;

      await tester.runAsync(
        () => reorderBudgetsAction(
          ref: h.ref,
          context: h.context,
          budgets: budgets,
          oldIndex: 0,
          newIndex: 2,
          onOptimisticOrder: (value) => optimistic = value,
          onRollback: (_) => fail('a successful reorder must not rollback'),
        ),
      );
      await tester.pumpAndSettle();

      expect(optimistic!.map((budget) => budget.id), ['goal-2', 'goal-1']);
      expect(fetches, greaterThan(1));
      expect(budgets.map((budget) => budget.id), ['goal-1', 'goal-2']);
    },
  );

  testWidgets(
    'reorder failure restores the immutable pre-drag order without refresh',
    (tester) async {
      var fetches = 0;
      final adapter = FakeDioAdapter(statusCode: 500, responseJson: {});
      final budgets = [_budget('goal-1', 0), _budget('goal-2', 1)];
      final h = await _mount(tester, [
        dioProvider.overrideWith(
          () => _FixedDioNotifier(buildFakeDio(adapter)),
        ),
        budgetsListProvider(null).overrideWith((ref) async {
          fetches++;
          return budgets;
        }),
      ]);
      h.container.listen(budgetsListProvider(null), (_, _) {});
      await tester.runAsync(
        () => h.container.read(budgetsListProvider(null).future),
      );
      List<Budget>? rollback;

      await tester.runAsync(
        () => reorderBudgetsAction(
          ref: h.ref,
          context: h.context,
          budgets: budgets,
          oldIndex: 1,
          newIndex: 0,
          onOptimisticOrder: (_) {},
          onRollback: (value) => rollback = value,
        ),
      );
      await tester.pumpAndSettle();

      expect(rollback!.map((budget) => budget.id), ['goal-1', 'goal-2']);
      expect(fetches, 1);
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );
}
