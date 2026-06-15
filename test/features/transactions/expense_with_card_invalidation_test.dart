import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/config/backend_config_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:finanzapp_v2/features/transactions/presentation/add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/fake_dio_adapter.dart';

class _FixedDioNotifier extends DioClientNotifier {
  _FixedDioNotifier(this._dio);
  final Dio _dio;
  @override
  Dio build() => _dio;
}

Account _account(String id, String name) =>
    Account(id: id, name: name, type: 'cash', balance: 500000, currency: 'COP');

Map<String, dynamic> _cardWithDebt(String id, String accountId) =>
    <String, dynamic>{
      'id': id,
      'account_id': accountId,
      'title': 'Oro Card',
      'total_debt': 95000.0,
      'month_debt': 20000.0,
    };

void main() {
  setUp(() async {
    // AddTransactionScreen formats dates with a locale-aware DateFormat.
    await initializeDateFormatting('es_CO');
    await initializeDateFormatting('es');
  });

  testWidgets(
    '5a.2: an expense paid with a credit card invalidates the debt rollups '
    '(vaultDebtSummary + creditCardsWithDebt), not only the create set',
    (tester) async {
      const ownerAccountId = 'owner-acc';
      const cardId = 'card-1';

      final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
      final dio = buildFakeDio(adapter);

      var debtFetches = 0;
      var cardsFetches = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWith(() => _FixedDioNotifier(dio)),
            accountsListProvider.overrideWith(
              (ref) async => [_account(ownerAccountId, 'Tarjeta')],
            ),
            budgetsListProvider(null).overrideWith((ref) async => <Budget>[]),
            householdProvider.overrideWith((ref) async => null),
            creditCardsWithDebtProvider.overrideWith((ref) async {
              cardsFetches++;
              return [_cardWithDebt(cardId, ownerAccountId)];
            }),
            vaultDebtSummaryProvider(ownerAccountId).overrideWith((ref) async {
              debtFetches++;
              return <Map<String, dynamic>>[];
            }),
          ],
          child: const MaterialApp(home: AddTransactionScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Keep the owner debt summary alive (the form never watches it) so the
      // ONLY thing that recomputes it is the submit handler's invalidate.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AddTransactionScreen)),
      );
      container.listen(vaultDebtSummaryProvider(ownerAccountId), (_, _) {});
      await tester.runAsync(() async {
        await container.read(vaultDebtSummaryProvider(ownerAccountId).future);
      });
      expect(debtFetches, 1, reason: 'owner debt summary primed once');
      final cardsBefore = cardsFetches;

      // Enter an amount (the first TextFormField).
      await tester.enterText(find.byType(TextFormField).first, '45000');
      await tester.pumpAndSettle();

      // Toggle "Pagado con Tarjeta de Crédito" ON — this marks the expense as
      // paid with a card and auto-selects the only card.
      await tester.ensureVisible(find.byType(Switch).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();

      // Submit the expense.
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Guardar Transacción'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Guardar Transacción'),
      );
      await tester.pumpAndSettle();

      // The transaction must have been created via POST.
      final posts = adapter.requests.where((r) => r.method == 'POST');
      expect(posts, isNotEmpty, reason: 'create transaction issued');

      // The debt rollups MUST have been invalidated for a card expense.
      expect(
        debtFetches,
        greaterThan(1),
        reason: 'vaultDebtSummary stale after a card expense (new-b7-2)',
      );
      expect(
        cardsFetches,
        greaterThan(cardsBefore),
        reason: 'creditCardsWithDebt stale after a card expense (new-b7-2)',
      );
    },
  );
}
