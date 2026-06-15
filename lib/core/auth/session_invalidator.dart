import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/pocket_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/assets/data/asset_repository.dart';
import 'package:finanzapp_v2/features/automation/data/automation_repository.dart';
import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/budgets/data/budget_config_provider.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:finanzapp_v2/features/history/data/history_provider.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/household/presentation/household_history_screen.dart';
import 'package:finanzapp_v2/features/periods/data/periods_provider.dart';
import 'package:finanzapp_v2/features/periods/data/settlement_provider.dart';
import 'package:finanzapp_v2/features/tax/data/tax_repository.dart';
import 'package:finanzapp_v2/features/transactions/data/household_transactions_provider.dart';
import 'package:finanzapp_v2/features/transactions/data/transactions_provider.dart';

/// The 22 VERIFIED user-data providers that hold the signed-in user's financial
/// state. On sign-out they must all be invalidated so the next user never sees
/// the previous user's cached data (spec 2c.1 / 2c.2, INV-1; design ADR-4).
///
/// Invalidating a `.family` base invalidates ALL of its argument variants
/// (Riverpod semantics; repo precedent: household_history_screen.dart:69-70).
///
/// Infrastructure providers are deliberately EXCLUDED — they are user-agnostic:
/// dioProvider, baseUrlProvider, repositories, supabaseClientProvider,
/// themeModeProvider, backendConfigProvider, the router. Invalidating them would
/// tear down the network/theme stack for no reason.
final List<ProviderOrFamily> userDataProviders = <ProviderOrFamily>[
  accountsListProvider,
  debtSummaryProvider,
  pocketsProvider,
  vaultItemsProvider,
  creditCardsProvider,
  allCreditCardsProvider,
  creditCardsWithDebtProvider,
  assetsListProvider,
  transactionsListProvider,
  budgetTransactionsProvider,
  householdTransactionsProvider,
  personalHistoryProvider,
  budgetsListProvider,
  budgetConfigProvider,
  householdProvider,
  householdSnapshotProvider,
  periodsListProvider,
  settlementProvider,
  taxStatusProvider,
  pendingPaymentsProvider,
  allRecurringPaymentsProvider,
  dashboardProvider,
];

/// A bootstrap-only provider that wires a single listener onto [authStateProvider]
/// and invalidates every user-data provider when the session transitions to
/// [AuthChangeEvent.signedOut].
///
/// Placement rationale (ADR-4): the listener lives here, NOT inside
/// `AuthController.signOut()`. This catches EVERY sign-out path — manual sign-out,
/// token-refresh failure, and the dio client's dead-session handling — from a
/// single source of truth, instead of coupling the auth feature to all data
/// features and missing externally-triggered sign-outs.
///
/// Eager-init it once at the root of the widget tree (see main.dart:
/// `ref.watch(sessionInvalidatorProvider)`) so the listener lives for the whole
/// session. It returns `void`; reading it only primes the subscription.
final sessionInvalidatorProvider = Provider<void>((ref) {
  // Guards against acting twice on the same logical sign-out. Riverpod's
  // ref.listen only fires on change and ref.invalidate is itself idempotent,
  // but tracking the last event keeps a repeated/duplicate signedOut from
  // re-running the loop needlessly.
  AuthChangeEvent? lastEvent;

  ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
    final event = next.asData?.value.event;
    if (event == null) return;
    if (event == lastEvent && event == AuthChangeEvent.signedOut) {
      // Already handled this signedOut; skip the redundant invalidation pass.
      return;
    }
    lastEvent = event;

    if (event == AuthChangeEvent.signedOut) {
      for (final provider in userDataProviders) {
        ref.invalidate(provider);
      }
    }
  });
}, name: 'sessionInvalidatorProvider');
