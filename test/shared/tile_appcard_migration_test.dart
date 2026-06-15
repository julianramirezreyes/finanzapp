import 'package:finanzapp_v2/shared/ui/widgets/account_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/account_with_pockets_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';
import 'package:finanzapp_v2/shared/ui/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Escenario 6c.1 [auto] — los tiles migrados (TransactionTile, AccountTile,
/// AccountWithPocketsTile) renderizan con [AppCard] (no `Card` crudo de
/// Material) y el `onTap` existente sigue disparando el callback.
void main() {
  setUpAll(() async {
    // TransactionTile usa DateFormat.MMMd('es_CO'); requiere init del locale.
    await initializeDateFormatting('es_CO');
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('6c.1 tiles migrados a AppCard', () {
    testWidgets('TransactionTile usa AppCard y dispara onTap', (tester) async {
      var tapped = false;
      await pump(
        tester,
        TransactionTile(
          description: 'Café',
          category: 'Comida',
          amount: 5000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          onTap: () => tapped = true,
        ),
      );

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);

      await tester.tap(find.byType(AppCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('AccountTile usa AppCard y dispara onTap', (tester) async {
      var tapped = false;
      await pump(
        tester,
        AccountTile(
          name: 'Ahorros',
          type: 'savings',
          balance: 100000,
          onTap: () => tapped = true,
        ),
      );

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);

      await tester.tap(find.byType(AppCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('AccountWithPocketsTile usa AppCard y dispara onTap', (
      tester,
    ) async {
      var tapped = false;
      await pump(
        tester,
        AccountWithPocketsTile(
          name: 'Cuenta',
          type: 'checking',
          balance: 50000,
          totalValue: 80000,
          pocketsCount: 2,
          pocketsTotal: 30000,
          onTap: () => tapped = true,
        ),
      );

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);

      await tester.tap(find.byType(AppCard));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
