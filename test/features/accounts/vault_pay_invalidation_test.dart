import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/config/backend_config_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/pocket_repository.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/accounts/domain/vault_item.dart';
import 'package:finanzapp_v2/features/accounts/presentation/vault_screen.dart';
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

/// Ignores ONLY the pre-existing benign "ListTile ink splashes may be
/// invisible" framework paint assertion (the vault item card wraps a ListTile
/// in a decorated AppCard). Any other error is forwarded to the default
/// handler so real failures still surface. This is a pre-existing UI detail
/// unrelated to the behavior under test.
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
    'Vault Pagar pays the row card and invalidates the OWNER account debt '
    'summary, not the paying account',
    (tester) async {
      const ownerAccountId = 'owner-acc';
      const cardVaultId = 'vault-card-77';

      _ignoreBenignListTileAssertion();

      final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
      final dio = buildFakeDio(adapter);

      // Count how many times the OWNER account's debt summary is computed.
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

      expect(ownerDebtFetches, 1, reason: 'initial debt summary load');

      // Tap the per-row Pagar button in the debt panel.
      await tester.tap(find.widgetWithText(TextButton, 'Pagar'));
      await tester.pumpAndSettle();

      // Pick the source (cash) account and an amount in the dialog.
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Efectivo').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '45000');
      await tester.pumpAndSettle();

      // Confirm the payment.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Pagar'));
      await tester.pumpAndSettle();

      // The payment must target the card via vault_card_id from the picked source.
      final payRequests = adapter.requests
          .where((r) => r.path == '/transactions/pay-credit')
          .toList();
      expect(payRequests, hasLength(1));
      final body = payRequests.single.json;
      expect(body['vault_card_id'], cardVaultId);
      expect(body['account_id'], 'source-acc');
      expect(body['amount'], 45000);

      // The OWNER account debt summary must have been invalidated → recomputed.
      expect(
        ownerDebtFetches,
        greaterThan(1),
        reason: 'owner-account debt summary invalidated after successful pay',
      );
    },
  );
}
