import 'package:finanzapp_v2/core/invalidation/data_invalidator.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/automation/data/automation_repository.dart';
import 'package:finanzapp_v2/features/automation/domain/recurring_payment.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/history/data/history_provider.dart';
import 'package:finanzapp_v2/features/history/domain/personal_history_summary.dart';
import 'package:finanzapp_v2/features/household/presentation/household_history_screen.dart';
import 'package:finanzapp_v2/features/transactions/data/transactions_provider.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 5a.6 / WU-5a.0: `invalidateAfterMutation(ref, scope: {...})` must recompute
/// EXACTLY the providers mapped to the requested mutation groups and NOTHING
/// outside that set. This is the regression guard for the group→providers map
/// (proposal R5).
///
/// Isolation pattern (precedent: session_invalidator_test): every non-family
/// user-data provider is stubbed with a trivial value so an invalidate-driven
/// rebuild never reaches real Supabase/network code; the asserted providers are
/// replaced with counter-backed overrides; and each asserted provider is kept
/// alive via `container.listen(...)` so `autoDispose` does NOT recompute it
/// between reads — the ONLY thing that may bump a counter is an explicit
/// `ref.invalidate`, which is exactly what we want to detect.
///
/// Seam for the `WidgetRef` argument: the public helper takes a [WidgetRef],
/// which a bare [ProviderContainer] cannot provide. We mount a minimal
/// [Consumer] to capture a real [WidgetRef] and reach the underlying container
/// via [ProviderScope.containerOf], so the counter/keep-alive machinery is
/// identical to the pure-container precedent.
void main() {
  // Stable family args used across cases.
  const historyArgs = (month: 6, year: 2026);
  const String? budgetArg = null;
  const snapshotArgs = (householdId: 'hh-1', year: 2026, month: 6);
  const String debtArg = 'acc-1';

  /// Stubs every non-family user-data provider touched by the helper so an
  /// invalidate-driven rebuild never hits real network code.
  List<Override> baseOverrides() => <Override>[
        accountsListProvider.overrideWith((ref) async => <Account>[]),
        transactionsListProvider.overrideWith((ref) async => <Transaction>[]),
        dashboardProvider.overrideWith((ref) async => _emptyDashboard()),
        creditCardsWithDebtProvider
            .overrideWith((ref) async => <Map<String, dynamic>>[]),
        pendingPaymentsProvider
            .overrideWith((ref) async => <RecurringPayment>[]),
      ];

  /// Mounts a Consumer, captures the WidgetRef + container, runs [body].
  ///
  /// [body] runs inside [WidgetTester.runAsync] so real `Future`s (provider
  /// async bodies, the `_pump` delay) actually complete — `testWidgets` defaults
  /// to a FakeAsync zone where a bare `Future.delayed` never fires, which would
  /// hang on `container.read(provider.future)`.
  Future<void> withRef(
    WidgetTester tester,
    List<Override> overrides,
    Future<void> Function(WidgetRef ref, ProviderContainer container) body,
  ) async {
    late WidgetRef capturedRef;
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            container = ProviderScope.containerOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.runAsync(() => body(capturedRef, container));
  }

  testWidgets('Case A: txEffects recomputes exactly the tx set', (tester) async {
    var dashboardBuilds = 0;
    var txBuilds = 0;
    var accountsBuilds = 0;
    var historyBuilds = 0;
    var budgetsBuilds = 0;
    var snapshotBuilds = 0;
    var pendingBuilds = 0; // OUT of set: must stay at 1.

    await withRef(
      tester,
      [
        ...baseOverrides(),
        dashboardProvider.overrideWith((ref) async {
          dashboardBuilds++;
          return _emptyDashboard();
        }),
        transactionsListProvider.overrideWith((ref) async {
          txBuilds++;
          return <Transaction>[];
        }),
        accountsListProvider.overrideWith((ref) async {
          accountsBuilds++;
          return <Account>[];
        }),
        personalHistoryProvider(historyArgs).overrideWith((ref) async {
          historyBuilds++;
          return _emptyHistory();
        }),
        budgetsListProvider(budgetArg).overrideWith((ref) async {
          budgetsBuilds++;
          return <Budget>[];
        }),
        householdSnapshotProvider(snapshotArgs).overrideWith((ref) async {
          snapshotBuilds++;
          return <String, dynamic>{};
        }),
        pendingPaymentsProvider.overrideWith((ref) async {
          pendingBuilds++;
          return <RecurringPayment>[];
        }),
      ],
      (ref, container) async {
        // Defeat autoDispose on every asserted provider.
        container.listen(dashboardProvider, (_, _) {});
        container.listen(transactionsListProvider, (_, _) {});
        container.listen(accountsListProvider, (_, _) {});
        container.listen(personalHistoryProvider(historyArgs), (_, _) {});
        container.listen(budgetsListProvider(budgetArg), (_, _) {});
        container.listen(householdSnapshotProvider(snapshotArgs), (_, _) {});
        container.listen(pendingPaymentsProvider, (_, _) {});

        // Prime caches: build #1 each.
        await container.read(dashboardProvider.future);
        await container.read(transactionsListProvider.future);
        await container.read(accountsListProvider.future);
        await container.read(personalHistoryProvider(historyArgs).future);
        await container.read(budgetsListProvider(budgetArg).future);
        await container.read(householdSnapshotProvider(snapshotArgs).future);
        await container.read(pendingPaymentsProvider.future);
        expect(dashboardBuilds, 1);
        expect(pendingBuilds, 1);

        invalidateAfterMutation(ref, scope: {DataMutation.txEffects});
        await _pump();

        await container.read(dashboardProvider.future);
        await container.read(transactionsListProvider.future);
        await container.read(accountsListProvider.future);
        await container.read(personalHistoryProvider(historyArgs).future);
        await container.read(budgetsListProvider(budgetArg).future);
        await container.read(householdSnapshotProvider(snapshotArgs).future);
        await container.read(pendingPaymentsProvider.future);

        expect(dashboardBuilds, 2, reason: 'dashboard in txEffects');
        expect(txBuilds, 2, reason: 'transactionsList in txEffects');
        expect(accountsBuilds, 2, reason: 'accountsList in txEffects');
        expect(historyBuilds, 2, reason: 'personalHistory (family base) in txEffects');
        expect(budgetsBuilds, 2, reason: 'budgetsList (family base) in txEffects');
        expect(snapshotBuilds, 2, reason: 'householdSnapshot (family base) in txEffects');
        expect(pendingBuilds, 1, reason: 'pendingPayments is OUTSIDE txEffects');
      },
    );
  });

  testWidgets('Case B: debtEffects recomputes only debt providers', (tester) async {
    var debtBuilds = 0;
    var cardsBuilds = 0;
    var txBuilds = 0; // OUT of set.

    await withRef(
      tester,
      [
        ...baseOverrides(),
        vaultDebtSummaryProvider(debtArg).overrideWith((ref) async {
          debtBuilds++;
          return <Map<String, dynamic>>[];
        }),
        creditCardsWithDebtProvider.overrideWith((ref) async {
          cardsBuilds++;
          return <Map<String, dynamic>>[];
        }),
        transactionsListProvider.overrideWith((ref) async {
          txBuilds++;
          return <Transaction>[];
        }),
      ],
      (ref, container) async {
        container.listen(vaultDebtSummaryProvider(debtArg), (_, _) {});
        container.listen(creditCardsWithDebtProvider, (_, _) {});
        container.listen(transactionsListProvider, (_, _) {});

        await container.read(vaultDebtSummaryProvider(debtArg).future);
        await container.read(creditCardsWithDebtProvider.future);
        await container.read(transactionsListProvider.future);
        expect(debtBuilds, 1);
        expect(cardsBuilds, 1);
        expect(txBuilds, 1);

        invalidateAfterMutation(ref, scope: {DataMutation.debtEffects});
        await _pump();

        await container.read(vaultDebtSummaryProvider(debtArg).future);
        await container.read(creditCardsWithDebtProvider.future);
        await container.read(transactionsListProvider.future);

        expect(debtBuilds, 2, reason: 'vaultDebtSummary (family base) in debtEffects');
        expect(cardsBuilds, 2, reason: 'creditCardsWithDebt in debtEffects');
        expect(txBuilds, 1, reason: 'transactionsList is OUTSIDE debtEffects');
      },
    );
  });

  testWidgets('Case C: balanceEffects recomputes only dashboard + accounts',
      (tester) async {
    var dashboardBuilds = 0;
    var accountsBuilds = 0;
    var txBuilds = 0; // OUT of set.

    await withRef(
      tester,
      [
        ...baseOverrides(),
        dashboardProvider.overrideWith((ref) async {
          dashboardBuilds++;
          return _emptyDashboard();
        }),
        accountsListProvider.overrideWith((ref) async {
          accountsBuilds++;
          return <Account>[];
        }),
        transactionsListProvider.overrideWith((ref) async {
          txBuilds++;
          return <Transaction>[];
        }),
      ],
      (ref, container) async {
        container.listen(dashboardProvider, (_, _) {});
        container.listen(accountsListProvider, (_, _) {});
        container.listen(transactionsListProvider, (_, _) {});

        await container.read(dashboardProvider.future);
        await container.read(accountsListProvider.future);
        await container.read(transactionsListProvider.future);
        expect(dashboardBuilds, 1);

        invalidateAfterMutation(ref, scope: {DataMutation.balanceEffects});
        await _pump();

        await container.read(dashboardProvider.future);
        await container.read(accountsListProvider.future);
        await container.read(transactionsListProvider.future);

        expect(dashboardBuilds, 2, reason: 'dashboard in balanceEffects');
        expect(accountsBuilds, 2, reason: 'accountsList in balanceEffects');
        expect(txBuilds, 1, reason: 'transactionsList is OUTSIDE balanceEffects');
      },
    );
  });

  testWidgets('Case D: budgetEffects recomputes only budgetsList',
      (tester) async {
    var budgetsBuilds = 0;
    var dashboardBuilds = 0; // OUT of set.

    await withRef(
      tester,
      [
        ...baseOverrides(),
        budgetsListProvider(budgetArg).overrideWith((ref) async {
          budgetsBuilds++;
          return <Budget>[];
        }),
        dashboardProvider.overrideWith((ref) async {
          dashboardBuilds++;
          return _emptyDashboard();
        }),
      ],
      (ref, container) async {
        container.listen(budgetsListProvider(budgetArg), (_, _) {});
        container.listen(dashboardProvider, (_, _) {});

        await container.read(budgetsListProvider(budgetArg).future);
        await container.read(dashboardProvider.future);
        expect(budgetsBuilds, 1);
        expect(dashboardBuilds, 1);

        invalidateAfterMutation(ref, scope: {DataMutation.budgetEffects});
        await _pump();

        await container.read(budgetsListProvider(budgetArg).future);
        await container.read(dashboardProvider.future);

        expect(budgetsBuilds, 2, reason: 'budgetsList in budgetEffects');
        expect(dashboardBuilds, 1, reason: 'dashboard is OUTSIDE budgetEffects');
      },
    );
  });

  testWidgets('Case E: union {txEffects, debtEffects} recomputes the exact union',
      (tester) async {
    var dashboardBuilds = 0; // txEffects
    var debtBuilds = 0; // debtEffects
    var cardsBuilds = 0; // debtEffects
    var pendingBuilds = 0; // OUT of both.

    await withRef(
      tester,
      [
        ...baseOverrides(),
        dashboardProvider.overrideWith((ref) async {
          dashboardBuilds++;
          return _emptyDashboard();
        }),
        vaultDebtSummaryProvider(debtArg).overrideWith((ref) async {
          debtBuilds++;
          return <Map<String, dynamic>>[];
        }),
        creditCardsWithDebtProvider.overrideWith((ref) async {
          cardsBuilds++;
          return <Map<String, dynamic>>[];
        }),
        pendingPaymentsProvider.overrideWith((ref) async {
          pendingBuilds++;
          return <RecurringPayment>[];
        }),
      ],
      (ref, container) async {
        container.listen(dashboardProvider, (_, _) {});
        container.listen(vaultDebtSummaryProvider(debtArg), (_, _) {});
        container.listen(creditCardsWithDebtProvider, (_, _) {});
        container.listen(pendingPaymentsProvider, (_, _) {});

        await container.read(dashboardProvider.future);
        await container.read(vaultDebtSummaryProvider(debtArg).future);
        await container.read(creditCardsWithDebtProvider.future);
        await container.read(pendingPaymentsProvider.future);

        invalidateAfterMutation(
          ref,
          scope: {DataMutation.txEffects, DataMutation.debtEffects},
        );
        await _pump();

        await container.read(dashboardProvider.future);
        await container.read(vaultDebtSummaryProvider(debtArg).future);
        await container.read(creditCardsWithDebtProvider.future);
        await container.read(pendingPaymentsProvider.future);

        expect(dashboardBuilds, 2, reason: 'dashboard recomputed (txEffects)');
        expect(debtBuilds, 2, reason: 'vaultDebtSummary recomputed (debtEffects)');
        expect(cardsBuilds, 2, reason: 'creditCardsWithDebt recomputed (debtEffects)');
        expect(pendingBuilds, 1, reason: 'pendingPayments outside the union');
      },
    );
  });
}

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 10));

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
