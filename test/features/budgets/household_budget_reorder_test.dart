import 'package:dio/dio.dart';
import 'dart:async';

import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/presentation/household_budget_tab.dart';
import 'package:finanzapp_v2/features/budgets/presentation/reorder_budgets_action.dart';
import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_card.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/household/domain/household.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budgets_tab_harness.dart';
import '../../support/fake_dio_adapter.dart';

Budget _budget(String id, int displayOrder) => Budget(
  id: id,
  userId: 'user-a',
  category: 'Goal $id',
  limitAmount: 100000,
  period: 'monthly',
  displayOrder: displayOrder,
);

class _DelayedHouseholdRepository extends BudgetRepository {
  _DelayedHouseholdRepository(this.gate) : super(Dio());

  final Completer<void> gate;
  final List<String?> scopes = [];
  final List<List<Budget>> requests = [];

  @override
  Future<void> reorderBudgets(
    List<Budget> budgets, {
    String? householdId,
  }) async {
    scopes.add(householdId);
    requests.add(List<Budget>.unmodifiable(budgets));
    await gate.future;
  }
}

class _ScriptedHouseholdRepository extends BudgetRepository {
  _ScriptedHouseholdRepository(this._steps) : super(Dio());

  final List<FutureOr<void> Function(List<Budget>)> _steps;
  final List<String?> scopes = [];
  final List<List<Budget>> requests = [];

  @override
  Future<void> reorderBudgets(
    List<Budget> budgets, {
    String? householdId,
  }) async {
    scopes.add(householdId);
    requests.add(List<Budget>.unmodifiable(budgets));
    await _steps.removeAt(0)(budgets);
  }
}

class _MutableBudgets {
  _MutableBudgets(this.value);
  List<Budget> value;
}

Future<ProviderContainer> _pumpHouseholdReorderTab(
  WidgetTester tester, {
  required Household household,
  required _MutableBudgets source,
  required BudgetRepository repository,
  int Function()? householdReads,
  int Function()? personalReads,
  int Function()? otherReads,
}) async {
  final container = ProviderContainer(
    overrides: [
      userProvider.overrideWithValue(fakeUser(id: household.userAId)),
      householdProvider.overrideWith((ref) async => household),
      budgetConfigProvider((
        type: 'household',
        householdId: household.id,
      )).overrideWith(
        (ref) async => fakeHouseholdConfig(householdId: household.id),
      ),
      budgetsListProvider(household.id).overrideWith((ref) async {
        householdReads?.call();
        return source.value;
      }),
      budgetsListProvider(null).overrideWith((ref) async {
        personalReads?.call();
        return [_budget('personal', 0)];
      }),
      budgetsListProvider('other-house').overrideWith((ref) async {
        otherReads?.call();
        return [_budget('other', 0)];
      }),
      budgetRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: HouseholdBudgetTab())),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void _reorder(WidgetTester tester, int oldIndex, int newIndex) {
  tester
      .widget<ReorderableListView>(find.byType(ReorderableListView))
      .onReorder!(oldIndex, newIndex);
}

List<String> _visibleIds(WidgetTester tester) => tester
    .widgetList<BudgetCard>(find.byType(BudgetCard))
    .map((card) => card.budget.id)
    .toList();

void main() {
  test('household reorder sends the captured household scope', () async {
    final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
    final repository = BudgetRepository(buildFakeDio(adapter));

    await repository.reorderBudgets([
      _budget('b', 1),
      _budget('a', 0),
    ], householdId: 'house-1');

    expect(adapter.lastRequest.path, '/budgets/reorder');
    expect(adapter.lastRequest.uri.queryParameters, {
      'household_id': 'house-1',
    });
  });

  testWidgets('household goals use stable-keyed reorderable list', (
    tester,
  ) async {
    final household = fakeHousehold();
    await pumpHouseholdBudgetTab(
      tester,
      household: household,
      config: fakeHouseholdConfig(householdId: household.id),
      budgets: [_budget('a', 0), _budget('b', 1)],
    );

    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(find.byKey(const ValueKey('household-budget-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('household-budget-b')), findsOneWidget);
  });

  testWidgets(
    'household reorder is immediate, save-locked, and scope-captured',
    (tester) async {
      final household = fakeHousehold(id: 'house-locked');
      final repository = _DelayedHouseholdRepository(Completer<void>());
      await pumpBudgetsScope(
        tester,
        child: const HouseholdBudgetTab(),
        overrides: [
          userProvider.overrideWithValue(fakeUser(id: household.userAId)),
          householdProvider.overrideWith((ref) async => household),
          budgetConfigProvider((
            type: 'household',
            householdId: household.id,
          )).overrideWith(
            (ref) async => fakeHouseholdConfig(householdId: household.id),
          ),
          budgetsListProvider(
            household.id,
          ).overrideWith((ref) async => [_budget('a', 0), _budget('b', 1)]),
          budgetRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final reorder = tester
          .widget<ReorderableListView>(find.byType(ReorderableListView))
          .onReorder!;
      reorder(0, 2);
      await tester.pump();
      expect(find.text('Guardando orden...'), findsOneWidget);
      expect(repository.requests.single.map((budget) => budget.id), ['b', 'a']);
      expect(repository.scopes, [household.id]);

      reorder(1, 0);
      await tester.pump();
      expect(repository.requests, hasLength(1));

      repository.gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Guardando orden...'), findsNothing);
    },
  );

  test('zero and one household budget reject reorder intents', () {
    expect(
      BudgetReorderIntent.tryFromDrag(
        budgets: const [],
        oldIndex: 0,
        newIndex: 0,
      ),
      isNull,
    );
    expect(
      BudgetReorderIntent.tryFromDrag(
        budgets: [_budget('only', 0)],
        oldIndex: 0,
        newIndex: 0,
      ),
      isNull,
    );
  });

  testWidgets(
    'first household 409 refreshes only its captured provider and retries with fresh expected orders',
    (tester) async {
      final household = fakeHousehold(id: 'house-retry');
      final source = _MutableBudgets([_budget('a', 0), _budget('b', 1)]);
      var householdReads = 0;
      var personalReads = 0;
      var otherReads = 0;
      final repository = _ScriptedHouseholdRepository([
        (_) async {
          source.value = [_budget('b', 4), _budget('a', 9)];
          throw BudgetRepositoryFailure(statusCode: 409);
        },
        (_) async {
          source.value = [_budget('a', 0), _budget('b', 1)];
        },
      ]);
      await _pumpHouseholdReorderTab(
        tester,
        household: household,
        source: source,
        repository: repository,
        householdReads: () => householdReads++,
        personalReads: () => personalReads++,
        otherReads: () => otherReads++,
      );

      _reorder(tester, 0, 2);
      await tester.pumpAndSettle();

      expect(repository.scopes, [household.id, household.id]);
      expect(repository.requests, hasLength(2));
      expect(repository.requests[1].map((b) => b.displayOrder), [4, 9]);
      expect(householdReads, greaterThanOrEqualTo(3));
      expect(personalReads, 0);
      expect(otherReads, 0);
    },
  );

  testWidgets(
    'second household 409 restores latest confirmed order and shows conflict guidance',
    (tester) async {
      final household = fakeHousehold(id: 'house-conflict');
      final source = _MutableBudgets([_budget('a', 0), _budget('b', 1)]);
      final repository = _ScriptedHouseholdRepository([
        (_) async {
          source.value = [_budget('b', 0), _budget('a', 1)];
          throw BudgetRepositoryFailure(statusCode: 409);
        },
        (_) async => throw BudgetRepositoryFailure(statusCode: 409),
      ]);
      await _pumpHouseholdReorderTab(
        tester,
        household: household,
        source: source,
        repository: repository,
      );

      _reorder(tester, 0, 2);
      await tester.pumpAndSettle();

      expect(repository.requests, hasLength(2));
      expect(_visibleIds(tester), ['b', 'a']);
      expect(
        find.text('La lista cambió. Actualiza e intenta reordenar de nuevo.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'terminal household non-conflict failure restores confirmed order and shows guidance',
    (tester) async {
      final household = fakeHousehold(id: 'house-failure');
      final source = _MutableBudgets([_budget('a', 0), _budget('b', 1)]);
      final repository = _ScriptedHouseholdRepository([
        (_) async => throw BudgetRepositoryFailure(statusCode: 500),
      ]);
      await _pumpHouseholdReorderTab(
        tester,
        household: household,
        source: source,
        repository: repository,
      );

      _reorder(tester, 0, 2);
      await tester.pumpAndSettle();

      expect(repository.requests, hasLength(1));
      expect(_visibleIds(tester), ['a', 'b']);
      expect(
        find.text('No se pudo guardar el orden. Intenta nuevamente.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('unmounted household tab ignores late reorder completion', (
    tester,
  ) async {
    final household = fakeHousehold(id: 'house-unmount');
    final repository = _DelayedHouseholdRepository(Completer<void>());
    final source = _MutableBudgets([_budget('a', 0), _budget('b', 1)]);
    await _pumpHouseholdReorderTab(
      tester,
      household: household,
      source: source,
      repository: repository,
    );

    _reorder(tester, 0, 2);
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    repository.gate.complete();
    await tester.pumpAndSettle();
    expect(repository.requests, hasLength(1));
  });
}
