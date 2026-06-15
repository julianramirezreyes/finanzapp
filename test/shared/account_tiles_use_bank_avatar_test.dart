import 'package:finanzapp_v2/shared/ui/widgets/account_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/account_with_pockets_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';
import 'package:finanzapp_v2/shared/ui/widgets/bank_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WU-5 — escenario 8.6 [auto]: ambos tiles de cuenta usan [BankAvatar] como
/// leading (no el viejo Container + Icon sobre stateFill), y conservan su
/// comportamiento de tap (AppCard de #6 sigue disparando onTap).
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('8.6 [auto] los tiles usan BankAvatar', () {
    testWidgets('AccountTile renderiza un BankAvatar y conserva onTap',
        (tester) async {
      var tapped = false;
      await pump(
        tester,
        AccountTile(
          name: 'Nequi',
          type: 'cash',
          balance: 100000,
          onTap: () => tapped = true,
        ),
      );

      expect(find.byType(BankAvatar), findsOneWidget);

      // El viejo leading ya no está: un BankAvatar conocido no expone Icon.
      final avatar = tester.widget<BankAvatar>(find.byType(BankAvatar));
      expect(avatar.name, 'Nequi');
      expect(avatar.type, 'cash');

      await tester.tap(find.byType(AppCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('AccountWithPocketsTile renderiza un BankAvatar y conserva onTap',
        (tester) async {
      var tapped = false;
      await pump(
        tester,
        AccountWithPocketsTile(
          name: 'Davivienda',
          type: 'checking',
          balance: 50000,
          totalValue: 80000,
          pocketsCount: 2,
          pocketsTotal: 30000,
          onTap: () => tapped = true,
        ),
      );

      expect(find.byType(BankAvatar), findsOneWidget);

      final avatar = tester.widget<BankAvatar>(find.byType(BankAvatar));
      expect(avatar.name, 'Davivienda');
      expect(avatar.type, 'checking');

      await tester.tap(find.byType(AppCard));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
