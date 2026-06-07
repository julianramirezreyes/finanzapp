import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/config/backend_config_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/accounts/presentation/pay_debt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

/// Minimal Notifier so [dioProvider] (a NotifierProvider) can be overridden
/// with a Dio wired to the fake adapter.
class _FixedDioNotifier extends DioClientNotifier {
  _FixedDioNotifier(this._dio);
  final Dio _dio;
  @override
  Dio build() => _dio;
}

Account _account(String id, String name, {String type = 'cash'}) =>
    Account(id: id, name: name, type: type, balance: 500000, currency: 'COP');

void main() {
  testWidgets(
    'PayDebtDialog pays the row card via vault_card_id from the picked source '
    'account',
    (tester) async {
      final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
      final dio = buildFakeDio(adapter);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWith(() => _FixedDioNotifier(dio)),
            accountsListProvider.overrideWith(
              (ref) async => [
                _account('acc-cash', 'Efectivo'),
                _account('acc-credit', 'TarjetaCredito', type: 'credit'),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PayDebtDialog(
                vaultCardId: 'vault-card-77',
                cardTitle: 'Oro Card',
                cardDebt: 95000,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pick the source (cash) account — credit accounts must be excluded.
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      // The credit account must NOT appear as a selectable source.
      expect(find.textContaining('TarjetaCredito'), findsNothing);
      await tester.tap(find.textContaining('Efectivo').last);
      await tester.pumpAndSettle();

      // Enter the amount.
      await tester.enterText(find.byType(TextField).first, '45000');
      await tester.pumpAndSettle();

      // Confirm.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Pagar'));
      await tester.pumpAndSettle();

      expect(adapter.requests, hasLength(1));
      final body = adapter.lastRequest.json;
      expect(adapter.lastRequest.path, '/transactions/pay-credit');
      expect(body['vault_card_id'], 'vault-card-77');
      expect(body['account_id'], 'acc-cash');
      expect(body['amount'], 45000);
      expect(body.containsKey('credit_card_account_id'), isFalse);
    },
  );
}
