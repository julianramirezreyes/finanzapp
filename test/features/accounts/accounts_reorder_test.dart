import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/config/backend_config_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/accounts/presentation/reorder_accounts_action.dart';
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

Account _account(String id, String name) =>
    Account(id: id, name: name, type: 'cash', balance: 100000, currency: 'COP');

/// Mounts a tiny Consumer + Scaffold so [reorderAccountsAction] runs with a real
/// [WidgetRef] and a [BuildContext] capable of hosting a SnackBar, and exposes
/// the [ProviderContainer] for keep-alive + counter assertions.
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
  return (
    ref: capturedRef,
    context: capturedContext,
    container: container,
  );
}

void main() {
  testWidgets(
    '5b.1: reorder with the network OK awaits the reorder request and '
    'invalidates accountsListProvider',
    (tester) async {
      var accountsFetches = 0;
      final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
      final dio = buildFakeDio(adapter);
      final accounts = [_account('acc-1', 'Efectivo'), _account('acc-2', 'Banco')];

      final h = await _mount(tester, [
        dioProvider.overrideWith(() => _FixedDioNotifier(dio)),
        accountsListProvider.overrideWith((ref) async {
          accountsFetches++;
          return accounts;
        }),
      ]);

      // Keep the list alive and prime it (defeat autoDispose) so the ONLY thing
      // that recomputes it is the action's invalidate.
      h.container.listen(accountsListProvider, (_, _) {});
      await tester.runAsync(() async {
        await h.container.read(accountsListProvider.future);
      });
      expect(accountsFetches, 1, reason: 'list loaded once');

      // Move the 2nd account to the top.
      await tester.runAsync(() async {
        await reorderAccountsAction(
          ref: h.ref,
          context: h.context,
          accounts: accounts,
          oldIndex: 1,
          newIndex: 0,
        );
      });
      await tester.pumpAndSettle();

      // The reorder must have been awaited and issued.
      final reorders = adapter.requests
          .where((r) => r.path == '/accounts/reorder')
          .toList();
      expect(reorders, hasLength(1), reason: 'reorder request issued');
      // It must carry the NEW order (acc-2 first), proving an immutable copy was
      // reordered and sent.
      final body = reorders.single.body as List;
      expect(body.first['id'], 'acc-2');
      expect(body.last['id'], 'acc-1');

      // On success the list must be invalidated → recomputed.
      expect(
        accountsFetches,
        greaterThan(1),
        reason: 'accountsListProvider invalidated after a successful reorder',
      );

      // The original provider list must NOT have been mutated in place.
      expect(accounts.first.id, 'acc-1',
          reason: 'provider list reordered via an immutable copy, not in place');
    },
  );

  testWidgets(
    '5b.2: reorder with the network FAIL shows an error snackbar and does NOT '
    'invalidate (the provider keeps the original order)',
    (tester) async {
      var accountsFetches = 0;
      // 500 makes AccountRepository.reorderAccounts throw.
      final adapter = FakeDioAdapter(statusCode: 500, responseJson: {});
      final dio = buildFakeDio(adapter);
      final accounts = [_account('acc-1', 'Efectivo'), _account('acc-2', 'Banco')];

      final h = await _mount(tester, [
        dioProvider.overrideWith(() => _FixedDioNotifier(dio)),
        accountsListProvider.overrideWith((ref) async {
          accountsFetches++;
          return accounts;
        }),
      ]);

      h.container.listen(accountsListProvider, (_, _) {});
      await tester.runAsync(() async {
        await h.container.read(accountsListProvider.future);
      });
      expect(accountsFetches, 1);

      await tester.runAsync(() async {
        await reorderAccountsAction(
          ref: h.ref,
          context: h.context,
          accounts: accounts,
          oldIndex: 1,
          newIndex: 0,
        );
      });
      await tester.pumpAndSettle();

      // The reorder was attempted.
      final reorders = adapter.requests
          .where((r) => r.path == '/accounts/reorder')
          .toList();
      expect(reorders, hasLength(1), reason: 'reorder attempt issued');

      // An error snackbar must be shown (the failure is surfaced, not lost).
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'error snackbar on failed reorder');

      // The list is NOT invalidated on failure: it keeps the original order.
      expect(accountsFetches, 1,
          reason: 'no invalidate on failure → original order preserved');
      expect(accounts.first.id, 'acc-1',
          reason: 'provider list never mutated in place (rollback)');
    },
  );
}
