import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/config/backend_config_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/pocket_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/accounts/domain/vault_item.dart';
import 'package:finanzapp_v2/features/accounts/presentation/vault_screen.dart';
import 'package:finanzapp_v2/features/dashboard/data/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_dio_adapter.dart';

class _FixedDioNotifier extends DioClientNotifier {
  _FixedDioNotifier(this._dio);
  final Dio _dio;
  @override
  Dio build() => _dio;
}

VaultItem _creditCard(String id, String accountId, String title) => VaultItem(
      id: id,
      accountId: accountId,
      title: title,
      data: '{"card_type":"credit"}',
      isCard: true,
      createdAt: DateTime.utc(2026, 1, 1),
    );

Account _account(String id, String name, {String type = 'cash'}) =>
    Account(id: id, name: name, type: type, balance: 500000, currency: 'COP');

void _ignoreBenignListTileAssertion() {
  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains(
      'ListTile background color or ink splashes may be invisible',
    )) {
      return;
    }
    previous?.call(details);
  };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    '5a.5: paying card debt from the vault invalidates the dashboard and '
    'creditCardsWithDebt (balance + debt effects), not just the owner debt '
    'summary',
    (tester) async {
      const ownerAccountId = 'owner-acc';
      const cardVaultId = 'vault-card-77';

      _ignoreBenignListTileAssertion();

      final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
      final dio = buildFakeDio(adapter);

      var dashboardFetches = 0;
      var cardsFetches = 0;
      var ownerDebtFetches = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWith(() => _FixedDioNotifier(dio)),
            vaultItemsProvider(ownerAccountId).overrideWith(
              (ref) async => [
                _creditCard(cardVaultId, ownerAccountId, 'Oro Card'),
              ],
            ),
            pocketsProvider(ownerAccountId).overrideWith((ref) async => []),
            vaultDebtSummaryProvider(ownerAccountId).overrideWith((ref) async {
              ownerDebtFetches++;
              return [
                {
                  'vault_card_id': cardVaultId,
                  'card_title': 'Oro Card',
                  'total_debt': 95000.0,
                  'month_debt': 20000.0,
                },
              ];
            }),
            creditCardsWithDebtProvider.overrideWith((ref) async {
              cardsFetches++;
              return <Map<String, dynamic>>[];
            }),
            dashboardProvider.overrideWith((ref) async {
              dashboardFetches++;
              return _emptyDashboard();
            }),
            accountsListProvider.overrideWith(
              (ref) async => [
                _account('source-acc', 'Efectivo'),
                _account(ownerAccountId, 'Tarjeta', type: 'credit'),
              ],
            ),
          ],
          child: const MaterialApp(
            home: VaultScreen(
              accountId: ownerAccountId,
              accountName: 'Mi Tarjeta',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Keep dashboard + cards-with-debt alive (the vault screen never watches
      // them) so the ONLY thing that recomputes them is the pay handler.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(VaultScreen)),
      );
      container.listen(dashboardProvider, (_, _) {});
      container.listen(creditCardsWithDebtProvider, (_, _) {});
      await tester.runAsync(() async {
        await container.read(dashboardProvider.future);
        await container.read(creditCardsWithDebtProvider.future);
      });

      expect(dashboardFetches, 1, reason: 'dashboard primed once');
      expect(ownerDebtFetches, 1, reason: 'initial debt summary load');
      final cardsBefore = cardsFetches;

      // Pay the row card via the per-row Pagar button.
      await tester.tap(find.widgetWithText(TextButton, 'Pagar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Efectivo').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '45000');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Pagar'));
      await tester.pumpAndSettle();

      // The pay request must have been issued.
      final payRequests = adapter.requests
          .where((r) => r.path == '/transactions/pay-credit')
          .toList();
      expect(payRequests, hasLength(1));

      // The owner debt summary must still recompute (pre-existing behavior).
      expect(ownerDebtFetches, greaterThan(1),
          reason: 'owner debt summary still invalidated');

      // The dashboard and cards-with-debt MUST now recompute too (new-b7-7).
      expect(dashboardFetches, greaterThan(1),
          reason: 'dashboard stale after paying card debt (new-b7-7)');
      expect(cardsFetches, greaterThan(cardsBefore),
          reason: 'creditCardsWithDebt stale after paying card debt (new-b7-7)');
    },
  );
}

DashboardData _emptyDashboard() => DashboardData(
      totalBalance: 0,
      yearlyIncome: 0,
      yearlyExpense: 0,
      accounts: const <Account>[],
      pocketsTotals: const <String, double>{},
      pocketsCounts: const <String, int>{},
    );
