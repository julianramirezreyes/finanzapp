import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:finanzapp_v2/features/history/data/history_provider.dart';
import 'package:finanzapp_v2/features/household/presentation/household_history_screen.dart';
import 'package:finanzapp_v2/features/transactions/data/transactions_provider.dart';

/// Logical groups of side effects a mutation produces. A call-site declares
/// WHAT it changed (the effect), not WHICH providers to invalidate — that
/// mapping lives here as the single source of truth (proposal §3.1).
///
/// - [txEffects]: anything that moves money via a transaction (create/delete tx,
///   recurring payment execution) — refreshes the dashboard, the transaction and
///   account lists, personal history, budgets and the household snapshot.
/// - [debtEffects]: anything that changes credit-card debt — refreshes the vault
///   debt summary and the cards-with-debt dropdown.
/// - [balanceEffects]: anything that changes an account's balance/ordering
///   without a transaction — refreshes the dashboard and the account list.
/// - [budgetEffects]: anything that changes a budget — refreshes the budget list.
enum DataMutation { txEffects, debtEffects, balanceEffects, budgetEffects }

/// Resolves the union of providers for a [scope], de-duplicated. Kept separate
/// from [invalidateAfterMutation] so the mapping is unit-testable without a ref.
///
/// `.family` providers are returned by their BASE: invalidating a family base
/// invalidates ALL of its argument variants (Riverpod semantics; repo precedent:
/// household_history_screen.dart:69-70). That covers every account/period/budget
/// arg without the call-site having to know which one is cached.
Set<ProviderOrFamily> providersFor(Set<DataMutation> scope) {
  final result = <ProviderOrFamily>{};
  for (final mutation in scope) {
    switch (mutation) {
      case DataMutation.txEffects:
        result.addAll(<ProviderOrFamily>[
          dashboardProvider,
          transactionsListProvider,
          accountsListProvider,
          personalHistoryProvider,
          budgetsListProvider,
          householdSnapshotProvider,
        ]);
      case DataMutation.debtEffects:
        result.addAll(<ProviderOrFamily>[
          vaultDebtSummaryProvider,
          creditCardsWithDebtProvider,
        ]);
      case DataMutation.balanceEffects:
        result.addAll(<ProviderOrFamily>[
          dashboardProvider,
          accountsListProvider,
        ]);
      case DataMutation.budgetEffects:
        result.add(budgetsListProvider);
    }
  }
  return result;
}

/// Invalidates exactly the providers affected by [scope], de-duplicated.
///
/// Call this from a mutation call-site AFTER the repository write succeeds,
/// passing the logical effects that occurred. The call-site stays decoupled
/// from the concrete provider list; this helper is the one place that knows
/// which provider goes stale after which mutation.
///
/// `ref` is a [WidgetRef] because every call-site is a widget/consumer; the
/// helper only uses `ref.invalidate`, which both `Ref` and `WidgetRef` expose.
void invalidateAfterMutation(
  WidgetRef ref, {
  required Set<DataMutation> scope,
}) {
  for (final provider in providersFor(scope)) {
    ref.invalidate(provider);
  }
}
