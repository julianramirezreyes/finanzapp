import 'dart:async';

import 'package:dio/dio.dart';
import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/presentation/personal_budget_tab.dart';
import 'package:finanzapp_v2/features/budgets/presentation/reorder_budgets_action.dart';
import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_card.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budgets_tab_harness.dart';
import '../../support/fake_dio_adapter.dart';

Budget _budget(String id, int displayOrder, {double currentAmount = 0}) =>
    Budget(
      id: id,
      userId: 'user-1',
      category: 'Goal $id',
      limitAmount: 100000,
      period: 'monthly',
      displayOrder: displayOrder,
      currentAmount: currentAmount,
    );

class _RecordingRepository extends BudgetRepository {
  _RecordingRepository(this._responses) : super(Dio());

  final List<Object?> _responses;
  final List<List<Budget>> requests = [];

  @override
  Future<void> reorderBudgets(
    List<Budget> budgets, {
    String? householdId,
  }) async {
    requests.add(List<Budget>.unmodifiable(budgets));
    final response = _responses.removeAt(0);
    if (response != null) throw response;
  }
}

class _DelayedRecordingRepository extends BudgetRepository {
  _DelayedRecordingRepository(this.gate) : super(Dio());

  final Completer<void> gate;
  final List<List<Budget>> requests = [];

  @override
  Future<void> reorderBudgets(
    List<Budget> budgets, {
    String? householdId,
  }) async {
    requests.add(List<Budget>.unmodifiable(budgets));
    await gate.future;
  }
}

class _MutableBudgets {
  _MutableBudgets(this.value);

  List<Budget> value;
}

class _ScriptedRepository extends BudgetRepository {
  _ScriptedRepository(this._steps) : super(Dio());

  final List<FutureOr<void> Function(List<Budget>)> _steps;
  final List<List<Budget>> requests = [];

  @override
  Future<void> reorderBudgets(
    List<Budget> budgets, {
    String? householdId,
  }) async {
    requests.add(List<Budget>.unmodifiable(budgets));
    await _steps.removeAt(0)(budgets);
  }
}

Future<ProviderContainer> _pumpReorderTab(
  WidgetTester tester, {
  required _MutableBudgets source,
  required BudgetRepository repository,
}) async {
  final container = ProviderContainer(
    overrides: [
      userProvider.overrideWithValue(fakeUser()),
      householdProvider.overrideWith((ref) async => null),
      budgetConfigProvider((
        type: 'personal',
        householdId: null,
      )).overrideWith((ref) async => fakePersonalConfig()),
      budgetsListProvider(null).overrideWith((ref) async => source.value),
      budgetRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PersonalBudgetTab())),
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

List<BudgetCard> _visibleBudgetCards(WidgetTester tester) =>
    tester.widgetList<BudgetCard>(find.byType(BudgetCard)).toList();

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

  test(
    'reorder failure preserves typed HTTP status and response body',
    () async {
      final repository = BudgetRepository(
        buildFakeDio(
          FakeDioAdapter(
            statusCode: 409,
            responseText: 'budget reorder: stale state',
          ),
        ),
      );

      await expectLater(
        repository.reorderBudgets([_budget('goal-1', 0)]),
        throwsA(
          isA<BudgetRepositoryFailure>()
              .having((failure) => failure.statusCode, 'status code', 409)
              .having(
                (failure) => failure.responseBody,
                'response body',
                'budget reorder: stale state',
              )
              .having(
                (failure) => failure.isConflict,
                'conflict classification',
                isTrue,
              ),
        ),
      );
    },
  );

  test(
    'non-409 reorder failure is not classified as a stale conflict',
    () async {
      final repository = BudgetRepository(
        buildFakeDio(
          FakeDioAdapter(statusCode: 500, responseText: 'server error'),
        ),
      );

      await expectLater(
        repository.reorderBudgets([_budget('goal-1', 0)]),
        throwsA(
          isA<BudgetRepositoryFailure>()
              .having((failure) => failure.statusCode, 'status code', 500)
              .having(
                (failure) => failure.isConflict,
                'conflict classification',
                isFalse,
              ),
        ),
      );
    },
  );

  test(
    'reorder retries exactly once from fresh canonical stable IDs',
    () async {
      final initial = [_budget('a', 0), _budget('b', 1), _budget('c', 2)];
      final refreshed = [_budget('c', 0), _budget('a', 1), _budget('b', 2)];
      final committed = [
        _budget('b', 0, currentAmount: 75),
        _budget('c', 1),
        _budget('a', 2),
      ];
      final repository = _RecordingRepository([
        BudgetRepositoryFailure(statusCode: 409, responseBody: 'stale'),
        null,
      ]);
      var refreshes = 0;

      final result = await executeBudgetReorder(
        repository: repository,
        budgets: initial,
        intent: BudgetReorderIntent.fromDrag(
          budgets: initial,
          oldIndex: 0,
          newIndex: 3,
        ),
        refreshCanonical: () async => switch (refreshes++) {
          0 => refreshed,
          _ => committed,
        },
      );

      expect(result.isSuccess, isTrue);
      expect(result.budgets.map((budget) => budget.id), ['b', 'c', 'a']);
      expect(result.budgets.first.currentAmount, 75);
      expect(refreshes, 2);
      expect(repository.requests, hasLength(2));
      expect(repository.requests[0].map((budget) => budget.id), [
        'b',
        'c',
        'a',
      ]);
      expect(repository.requests[1].map((budget) => budget.id), [
        'c',
        'b',
        'a',
      ]);
      expect(repository.requests[1].map((budget) => budget.displayOrder), [
        0,
        2,
        1,
      ]);
    },
  );

  test('retry failure returns the latest refreshed canonical order', () async {
    final initial = [_budget('a', 0), _budget('b', 1)];
    final refreshed = [_budget('b', 0), _budget('a', 1)];
    final repository = _RecordingRepository([
      BudgetRepositoryFailure(statusCode: 409),
      BudgetRepositoryFailure(statusCode: 500),
    ]);

    final result = await executeBudgetReorder(
      repository: repository,
      budgets: initial,
      intent: BudgetReorderIntent.fromDrag(
        budgets: initial,
        oldIndex: 0,
        newIndex: 2,
      ),
      refreshCanonical: () async => refreshed,
    );

    expect(result.isSuccess, isFalse);
    expect(result.isConflict, isTrue);
    expect(result.budgets.map((budget) => budget.id), ['b', 'a']);
    expect(repository.requests, hasLength(2));
  });

  test(
    'conflict refresh failure terminates without another persistence attempt',
    () async {
      final initial = [_budget('a', 0), _budget('b', 1)];
      final repository = _RecordingRepository([
        BudgetRepositoryFailure(statusCode: 409),
      ]);

      final result = await executeBudgetReorder(
        repository: repository,
        budgets: initial,
        intent: BudgetReorderIntent.fromDrag(
          budgets: initial,
          oldIndex: 0,
          newIndex: 2,
        ),
        refreshCanonical: () =>
            Future<List<Budget>>.error(StateError('offline')),
      );

      expect(result.isSuccess, isFalse);
      expect(result.isConflict, isTrue);
      expect(result.budgets.map((budget) => budget.id), ['a', 'b']);
      expect(repository.requests, hasLength(1));
    },
  );

  test('non-conflict failure does not refresh or retry', () async {
    final initial = [_budget('a', 0), _budget('b', 1)];
    final repository = _RecordingRepository([
      BudgetRepositoryFailure(statusCode: 500),
    ]);
    var refreshes = 0;

    final result = await executeBudgetReorder(
      repository: repository,
      budgets: initial,
      intent: BudgetReorderIntent.fromDrag(
        budgets: initial,
        oldIndex: 1,
        newIndex: 0,
      ),
      refreshCanonical: () async {
        refreshes++;
        return initial;
      },
    );

    expect(result.isSuccess, isFalse);
    expect(result.isConflict, isFalse);
    expect(result.budgets.map((budget) => budget.id), ['a', 'b']);
    expect(repository.requests, hasLength(1));
    expect(refreshes, 0);
  });

  test('zero or one budget creates no reorder intent', () {
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
    'tab locks drag input and shows saving feedback until persistence settles',
    (tester) async {
      final gate = Completer<void>();
      final repository = _DelayedRecordingRepository(gate);
      final budgets = [_budget('a', 0), _budget('b', 1)];

      await pumpBudgetsScope(
        tester,
        child: const PersonalBudgetTab(),
        overrides: <Override>[
          userProvider.overrideWithValue(fakeUser()),
          householdProvider.overrideWith((ref) async => null),
          budgetConfigProvider((
            type: 'personal',
            householdId: null,
          )).overrideWith((ref) async => fakePersonalConfig()),
          budgetsListProvider(null).overrideWith((ref) async => budgets),
          budgetRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final firstCallback = tester
          .widget<ReorderableListView>(find.byType(ReorderableListView))
          .onReorder!;
      firstCallback(0, 2);
      await tester.pump();

      expect(find.text('Guardando orden...'), findsOneWidget);
      expect(repository.requests, hasLength(1));

      firstCallback(1, 0);
      await tester.pump();
      expect(repository.requests, hasLength(1));

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Guardando orden...'), findsNothing);
    },
  );

  testWidgets('an unmounted tab ignores a late persistence completion', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = _DelayedRecordingRepository(gate);
    final budgets = [_budget('a', 0), _budget('b', 1)];

    await pumpBudgetsScope(
      tester,
      child: const PersonalBudgetTab(),
      overrides: <Override>[
        userProvider.overrideWithValue(fakeUser()),
        householdProvider.overrideWith((ref) async => null),
        budgetConfigProvider((
          type: 'personal',
          householdId: null,
        )).overrideWith((ref) async => fakePersonalConfig()),
        budgetsListProvider(null).overrideWith((ref) async => budgets),
        budgetRepositoryProvider.overrideWithValue(repository),
      ],
    );

    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorder!(0, 2);
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.requests, hasLength(1));
  });

  testWidgets(
    'mounted success reconciles the confirmed order and allows a consecutive reorder',
    (tester) async {
      final firstSave = Completer<void>();
      final source = _MutableBudgets([
        _budget('a', 0),
        _budget('b', 1),
        _budget('c', 2),
      ]);
      final repository = _ScriptedRepository([(_) => firstSave.future, (_) {}]);
      final container = await _pumpReorderTab(
        tester,
        source: source,
        repository: repository,
      );

      _reorder(tester, 0, 3);
      await tester.pump();
      expect(_visibleBudgetCards(tester).map((card) => card.budget.id), [
        'b',
        'c',
        'a',
      ]);

      source.value = [_budget('b', 0), _budget('c', 1), _budget('a', 2)];
      firstSave.complete();
      await tester.pumpAndSettle();
      expect(_visibleBudgetCards(tester).map((card) => card.budget.id), [
        'b',
        'c',
        'a',
      ]);
      expect(find.text('Guardando orden...'), findsNothing);

      source.value = [_budget('c', 0), _budget('a', 1), _budget('b', 2)];
      _reorder(tester, 0, 3);
      await tester.pumpAndSettle();
      expect(repository.requests, hasLength(2));
      expect(_visibleBudgetCards(tester).map((card) => card.budget.id), [
        'c',
        'a',
        'b',
      ]);
      expect(container.read(budgetsListProvider(null)).value, source.value);
    },
  );

  testWidgets(
    'provider refresh rebases optimistic IDs onto authoritative movement amounts',
    (tester) async {
      final save = Completer<void>();
      final source = _MutableBudgets([_budget('a', 0), _budget('b', 1)]);
      final repository = _ScriptedRepository([(_) => save.future]);
      final container = await _pumpReorderTab(
        tester,
        source: source,
        repository: repository,
      );

      _reorder(tester, 0, 2);
      await tester.pump();
      source.value = [
        _budget('a', 0, currentAmount: 42),
        _budget('b', 1, currentAmount: 17),
      ];
      container.invalidate(budgetsListProvider(null));
      await tester.pump();
      await tester.pump();

      final cards = _visibleBudgetCards(tester);
      expect(cards.map((card) => card.budget.id), ['b', 'a']);
      expect(cards.map((card) => card.currentAmount), [17, 42]);
      save.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'mounted conflict rollback restores canonical order and explains it',
    (tester) async {
      final source = _MutableBudgets([_budget('a', 0), _budget('b', 1)]);
      final repository = _ScriptedRepository([
        (_) async => throw BudgetRepositoryFailure(statusCode: 409),
        (_) async => throw BudgetRepositoryFailure(statusCode: 500),
      ]);
      await _pumpReorderTab(tester, source: source, repository: repository);

      _reorder(tester, 0, 2);
      await tester.pumpAndSettle();

      expect(_visibleBudgetCards(tester).map((card) => card.budget.id), [
        'a',
        'b',
      ]);
      expect(
        find.text('La lista cambió. Actualiza e intenta reordenar de nuevo.'),
        findsOneWidget,
      );
      expect(repository.requests, hasLength(2));
    },
  );

  testWidgets('mounted non-conflict failure restores order without retry', (
    tester,
  ) async {
    final source = _MutableBudgets([_budget('a', 0), _budget('b', 1)]);
    final repository = _ScriptedRepository([
      (_) async => throw BudgetRepositoryFailure(statusCode: 500),
    ]);
    await _pumpReorderTab(tester, source: source, repository: repository);

    _reorder(tester, 0, 2);
    await tester.pumpAndSettle();

    expect(_visibleBudgetCards(tester).map((card) => card.budget.id), [
      'a',
      'b',
    ]);
    expect(
      find.text('No se pudo guardar el orden. Intenta nuevamente.'),
      findsOneWidget,
    );
    expect(repository.requests, hasLength(1));
  });
}
