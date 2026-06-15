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

/// Builds a VaultScreen wired so a vault-item mutation can be driven, and
/// returns the debt-summary + cards-with-debt fetch counters via [onDebtFetch]
/// and [onCardsFetch]. Both debt providers are kept alive via [container.listen]
/// so the ONLY thing that recomputes them is the mutation handler's invalidate.
Future<({ProviderContainer container, FakeDioAdapter adapter})> _pumpVault(
  WidgetTester tester, {
  required String accountId,
  required void Function() onDebtFetch,
  required void Function() onCardsFetch,
  required String cardVaultId,
}) async {
  _ignoreBenignListTileAssertion();
  final adapter = FakeDioAdapter(statusCode: 200, responseList: <dynamic>[]);
  final dio = buildFakeDio(adapter);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioProvider.overrideWith(() => _FixedDioNotifier(dio)),
        vaultItemsProvider(accountId).overrideWith(
          (ref) async => [_creditCard(cardVaultId, accountId, 'Oro Card')],
        ),
        pocketsProvider(accountId).overrideWith((ref) async => []),
        vaultDebtSummaryProvider(accountId).overrideWith((ref) async {
          onDebtFetch();
          return <Map<String, dynamic>>[];
        }),
        creditCardsWithDebtProvider.overrideWith((ref) async {
          onCardsFetch();
          return <Map<String, dynamic>>[];
        }),
        accountsListProvider.overrideWith(
          (ref) async => [_account(accountId, 'Tarjeta', type: 'credit')],
        ),
      ],
      child: MaterialApp(
        home: VaultScreen(accountId: accountId, accountName: 'Mi Tarjeta'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final container = ProviderScope.containerOf(
    tester.element(find.byType(VaultScreen)),
  );
  container.listen(vaultDebtSummaryProvider(accountId), (_, _) {});
  container.listen(creditCardsWithDebtProvider, (_, _) {});
  await tester.runAsync(() async {
    await container.read(vaultDebtSummaryProvider(accountId).future);
    await container.read(creditCardsWithDebtProvider.future);
  });
  return (container: container, adapter: adapter);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    '5a.4 (create): creating a vault item invalidates the debt rollups '
    '(vaultDebtSummary + creditCardsWithDebt), not just vaultItems',
    (tester) async {
      const accountId = 'owner-acc';
      var debtFetches = 0;
      var cardsFetches = 0;

      final res = await _pumpVault(
        tester,
        accountId: accountId,
        cardVaultId: 'card-existing',
        onDebtFetch: () => debtFetches++,
        onCardsFetch: () => cardsFetches++,
      );

      expect(debtFetches, 1, reason: 'debt summary primed once');
      final cardsBefore = cardsFetches;

      // Open the "new item" dialog via the FAB.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Give the card an alias (the first TextField in the dialog) and save.
      await tester.enterText(find.byType(TextField).first, 'Visa Oro');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();

      // A POST creating the vault item must have been issued.
      final posts = res.adapter.requests.where((r) => r.method == 'POST');
      expect(posts, isNotEmpty, reason: 'create vault item issued');

      expect(debtFetches, greaterThan(1),
          reason: 'vaultDebtSummary stale after creating a card (new-b7-6)');
      expect(cardsFetches, greaterThan(cardsBefore),
          reason: 'creditCardsWithDebt stale after creating a card (new-b7-6)');
    },
  );

  testWidgets(
    '5a.4 (edit): editing a vault item invalidates the debt rollups',
    (tester) async {
      const accountId = 'owner-acc';
      var debtFetches = 0;
      var cardsFetches = 0;

      final res = await _pumpVault(
        tester,
        accountId: accountId,
        cardVaultId: 'card-existing',
        onDebtFetch: () => debtFetches++,
        onCardsFetch: () => cardsFetches++,
      );

      expect(debtFetches, 1, reason: 'debt summary primed once');
      final cardsBefore = cardsFetches;

      // Expand the existing card (it is an ExpansionTile) to reveal its actions.
      await tester.tap(find.text('Oro Card'));
      await tester.pumpAndSettle();
      // Open the card's edit dialog ("Editar") and save.
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Editar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Editar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();

      // A PUT updating the vault item must have been issued.
      final puts = res.adapter.requests.where((r) => r.method == 'PUT');
      expect(puts, isNotEmpty, reason: 'update vault item issued');

      expect(debtFetches, greaterThan(1),
          reason: 'vaultDebtSummary stale after editing a card (new-b7-6)');
      expect(cardsFetches, greaterThan(cardsBefore),
          reason: 'creditCardsWithDebt stale after editing a card (new-b7-6)');
    },
  );
}
