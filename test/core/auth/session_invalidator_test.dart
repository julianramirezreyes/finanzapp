import 'dart:async';

import 'package:finanzapp_v2/core/auth/session_invalidator.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/accounts/domain/vault_item.dart';
import 'package:finanzapp_v2/features/assets/data/asset_repository.dart';
import 'package:finanzapp_v2/features/assets/domain/asset.dart';
import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/automation/data/automation_repository.dart';
import 'package:finanzapp_v2/features/automation/domain/recurring_payment.dart';
import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/periods/data/periods_provider.dart';
import 'package:finanzapp_v2/features/periods/domain/period.dart';
import 'package:finanzapp_v2/features/transactions/data/transactions_provider.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 2c.1 / 2c.2 / INV-1: when the auth state transitions to [signedOut],
/// every user-data provider MUST be invalidated so no previous-user data
/// survives into the next session. We assert the OBSERVABLE end state: a
/// provider that was primed (cached) is recomputed after sign-out.
///
/// Seam: we drive the existing [authStateProvider] (a `StreamProvider<AuthState>`
/// that already wraps `supabase.auth.onAuthStateChange`) through a
/// [StreamController] override, so no real Supabase client is needed.
///
/// Hermetic isolation: the listener calls `ref.invalidate` on every user-data
/// provider, which makes Riverpod (re)build the plain (non-family) ones even if
/// they were never read. Their real bodies hit `Supabase.instance` (uninitialized
/// in a unit test). So we stub EVERY non-family user-data provider with a trivial
/// value via [_baseOverrides]; the providers a given test asserts on are replaced
/// with counter-backed overrides on top, so a recompute is observable as a bump.
///
/// Several user-data providers are `autoDispose`; tests hold a live
/// `container.listen(...)` on the asserted ones so auto-dispose does NOT recompute
/// them between reads — the ONLY thing that may recompute them is an explicit
/// `ref.invalidate`, which is exactly what we want to detect.
void main() {
  late StreamController<AuthState> authEvents;

  setUp(() {
    authEvents = StreamController<AuthState>.broadcast();
  });

  tearDown(() async {
    await authEvents.close();
  });

  /// Stubs the auth seam + every non-family user-data provider so invalidation
  /// never reaches real Supabase/network code. Family providers are NOT stubbed
  /// here because invalidating a family base does not eagerly rebuild an
  /// unmounted argument.
  List<Override> baseOverrides() => <Override>[
        authStateProvider.overrideWith((ref) => authEvents.stream),
        accountsListProvider.overrideWith((ref) async => <Account>[]),
        assetsListProvider.overrideWith((ref) async => <Asset>[]),
        allCreditCardsProvider.overrideWith((ref) async => <VaultItem>[]),
        creditCardsWithDebtProvider
            .overrideWith((ref) async => <Map<String, dynamic>>[]),
        transactionsListProvider.overrideWith((ref) async => <Transaction>[]),
        householdProvider.overrideWith((ref) async => null),
        pendingPaymentsProvider
            .overrideWith((ref) async => <RecurringPayment>[]),
        allRecurringPaymentsProvider
            .overrideWith((ref) async => <RecurringPayment>[]),
        dashboardProvider.overrideWith((ref) async => _emptyDashboard()),
      ];

  test(
    '2c.1: signedOut invalidates user-data providers (each is recomputed)',
    () async {
      var accountsBuilds = 0;
      var assetsBuilds = 0;
      var periodsBuilds = 0;

      final container = ProviderContainer(
        overrides: [
          ...baseOverrides(),
          accountsListProvider.overrideWith((ref) async {
            accountsBuilds++;
            return <Account>[];
          }),
          assetsListProvider.overrideWith((ref) async {
            assetsBuilds++;
            return <Asset>[];
          }),
          // .family base — invalidating the base must invalidate this arg too.
          periodsListProvider('hh-1').overrideWith((ref) async {
            periodsBuilds++;
            return <Period>[];
          }),
        ],
      );
      addTearDown(container.dispose);

      // Eager-init the listener (this is what main.dart does via ref.watch).
      container.read(sessionInvalidatorProvider);

      // Keep-alive subscriptions defeat autoDispose so only invalidation rebuilds.
      container.listen(accountsListProvider, (_, _) {});
      container.listen(assetsListProvider, (_, _) {});
      container.listen(periodsListProvider('hh-1'), (_, _) {});

      // Prime caches: first read computes build #1 for each.
      await container.read(accountsListProvider.future);
      await container.read(assetsListProvider.future);
      await container.read(periodsListProvider('hh-1').future);
      expect(accountsBuilds, 1);
      expect(assetsBuilds, 1);
      expect(periodsBuilds, 1);

      // Re-reading WITHOUT a sign-out hits the cache (no recompute).
      await container.read(accountsListProvider.future);
      expect(accountsBuilds, 1, reason: 'cached read must not recompute');

      // Sign out.
      authEvents.add(const AuthState(AuthChangeEvent.signedOut, null));
      await _pump();

      // After invalidation the next read recomputes -> build #2 (clean state).
      await container.read(accountsListProvider.future);
      await container.read(assetsListProvider.future);
      await container.read(periodsListProvider('hh-1').future);
      expect(
        accountsBuilds,
        2,
        reason: 'accountsListProvider must be invalidated on signedOut',
      );
      expect(
        assetsBuilds,
        2,
        reason: 'assetsListProvider must be invalidated on signedOut',
      );
      expect(
        periodsBuilds,
        2,
        reason: 'periodsListProvider family arg must be invalidated on signedOut',
      );
    },
  );

  test(
    '2c.2: a non-signedOut event does NOT invalidate user data',
    () async {
      var accountsBuilds = 0;

      final container = ProviderContainer(
        overrides: [
          ...baseOverrides(),
          accountsListProvider.overrideWith((ref) async {
            accountsBuilds++;
            return <Account>[];
          }),
        ],
      );
      addTearDown(container.dispose);
      container.read(sessionInvalidatorProvider);
      container.listen(accountsListProvider, (_, _) {});

      await container.read(accountsListProvider.future);
      expect(accountsBuilds, 1);

      // tokenRefreshed / signedIn must NOT trigger invalidation.
      authEvents.add(const AuthState(AuthChangeEvent.tokenRefreshed, null));
      authEvents.add(const AuthState(AuthChangeEvent.signedIn, null));
      await _pump();

      await container.read(accountsListProvider.future);
      expect(
        accountsBuilds,
        1,
        reason: 'non-signedOut events must not invalidate cached data',
      );
    },
  );

  test(
    'INV-1: a duplicate signedOut is guarded (no re-invalidation, no throw)',
    () async {
      var accountsBuilds = 0;

      final container = ProviderContainer(
        overrides: [
          ...baseOverrides(),
          accountsListProvider.overrideWith((ref) async {
            accountsBuilds++;
            return <Account>[];
          }),
        ],
      );
      addTearDown(container.dispose);
      container.read(sessionInvalidatorProvider);
      container.listen(accountsListProvider, (_, _) {});

      await container.read(accountsListProvider.future);
      expect(accountsBuilds, 1);

      authEvents.add(const AuthState(AuthChangeEvent.signedOut, null));
      await _pump();
      await container.read(accountsListProvider.future);
      expect(accountsBuilds, 2);

      // A duplicate signedOut (same event back-to-back) must be a clean no-op:
      // the guard skips the redundant pass, so the count stays at 2.
      authEvents.add(const AuthState(AuthChangeEvent.signedOut, null));
      await _pump();
      await container.read(accountsListProvider.future);
      expect(
        accountsBuilds,
        2,
        reason: 'a duplicate signedOut is guarded (no re-invalidation, no throw)',
      );
    },
  );
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
