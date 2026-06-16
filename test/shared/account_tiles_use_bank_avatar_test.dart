import 'package:finanzapp_v2/shared/ui/widgets/account_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/account_with_pockets_tile.dart';
import 'package:finanzapp_v2/shared/ui/widgets/app_card.dart';
import 'package:finanzapp_v2/shared/ui/widgets/bank_avatar.dart';
import 'package:finanzapp_v2/shared/ui/widgets/branded_account_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WU-5 (#8 Fase 1) + WU-Lb2 (#8 Fase 2) — escenario 8.6 / L.6 [auto]:
/// ambos tiles usan [BankAvatar] como leading Y envuelven su contenido en un
/// [BrandedAccountSurface], conservando onTap/onLongPress, la fila de bolsillos
/// y el drag handle.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('8.6 / L.6 [auto] los tiles usan BankAvatar + BrandedAccountSurface', () {
    testWidgets('AccountTile usa surface, BankAvatar y conserva onTap/onLongPress',
        (tester) async {
      var tapped = false;
      var longPressed = false;
      await pump(
        tester,
        AccountTile(
          name: 'Nequi',
          type: 'cash',
          balance: 100000,
          onTap: () => tapped = true,
          onLongPress: () => longPressed = true,
        ),
      );

      expect(find.byType(BankAvatar), findsOneWidget);
      expect(find.byType(BrandedAccountSurface), findsOneWidget);

      final avatar = tester.widget<BankAvatar>(find.byType(BankAvatar));
      expect(avatar.name, 'Nequi');
      expect(avatar.type, 'cash');

      await tester.tap(find.byType(AppCard));
      await tester.pump();
      expect(tapped, isTrue);

      await tester.longPress(find.byType(AppCard));
      await tester.pump();
      expect(longPressed, isTrue);
    });

    testWidgets('AccountTile con showDragHandle muestra el drag handle',
        (tester) async {
      await pump(
        tester,
        const AccountTile(
          name: 'Nequi',
          type: 'cash',
          balance: 100000,
          showDragHandle: true,
        ),
      );

      expect(find.byType(BrandedAccountSurface), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
    });

    testWidgets(
        'AccountWithPocketsTile usa surface, BankAvatar y conserva onTap/onLongPress',
        (tester) async {
      var tapped = false;
      var longPressed = false;
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
          onLongPress: () => longPressed = true,
        ),
      );

      expect(find.byType(BankAvatar), findsOneWidget);
      expect(find.byType(BrandedAccountSurface), findsOneWidget);

      final avatar = tester.widget<BankAvatar>(find.byType(BankAvatar));
      expect(avatar.name, 'Davivienda');
      expect(avatar.type, 'checking');

      // La fila de bolsillos sigue presente con pocketsCount > 0.
      expect(find.textContaining('bolsillo'), findsOneWidget);

      await tester.tap(find.byType(AppCard));
      await tester.pump();
      expect(tapped, isTrue);

      await tester.longPress(find.byType(AppCard));
      await tester.pump();
      expect(longPressed, isTrue);
    });

    testWidgets(
        'AccountWithPocketsTile con showDragHandle muestra el drag handle',
        (tester) async {
      await pump(
        tester,
        const AccountWithPocketsTile(
          name: 'Davivienda',
          type: 'checking',
          balance: 50000,
          totalValue: 80000,
          pocketsCount: 0,
          pocketsTotal: 0,
          showDragHandle: true,
        ),
      );

      expect(find.byType(BrandedAccountSurface), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
    });
  });
}
