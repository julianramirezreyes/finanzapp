import 'package:finanzapp_v2/shared/ui/widgets/vault_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// WU-empty — estado VACÍO de la bóveda con logo de marca tenue de fondo.
/// Cuando el nombre detecta una marca CON asset, el empty state muestra un
/// watermark grande y MUY tenue (opacity ~0.05-0.07) detrás del EmptyState,
/// SIN tapar el título 'Bóveda vacía' ni el botón 'Agregar Ítem'. Si la marca
/// es desconocida (sin asset), degrada: no muestra watermark, pero el empty
/// state sigue intacto.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required Brightness brightness,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    final label = brightness == Brightness.dark ? 'dark' : 'light';

    group('VaultEmptyState ($label)', () {
      testWidgets('marca conocida (Trii) muestra watermark tenue + EmptyState',
          (tester) async {
        await pump(
          tester,
          VaultEmptyState(accountName: 'Trii', onAddItem: () {}),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        // El EmptyState sigue visible y legible.
        expect(find.text('Bóveda vacía'), findsOneWidget);
        expect(find.text('Agregar Ítem'), findsOneWidget);
        // El watermark de marca (Trii = SVG) está presente.
        expect(find.byType(SvgPicture), findsWidgets);
        // Es MUY tenue: hay un Opacity con opacidad <= 0.1 envolviendo el logo.
        final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
        expect(
          opacities.any((o) => o.opacity > 0 && o.opacity <= 0.1),
          isTrue,
          reason: 'el watermark de marca debe ser muy tenue (<= 0.1)',
        );
      });

      testWidgets('marca desconocida (Banco Raro) degrada sin watermark',
          (tester) async {
        await pump(
          tester,
          VaultEmptyState(accountName: 'Banco Raro', onAddItem: () {}),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        // EmptyState intacto.
        expect(find.text('Bóveda vacía'), findsOneWidget);
        expect(find.text('Agregar Ítem'), findsOneWidget);
        // Sin marca -> sin watermark de logo.
        expect(find.byType(SvgPicture), findsNothing);
      });

      testWidgets('el botón Agregar Ítem dispara onAddItem', (tester) async {
        var tapped = 0;
        await pump(
          tester,
          VaultEmptyState(accountName: 'Trii', onAddItem: () => tapped++),
          brightness: brightness,
        );
        await tester.tap(find.text('Agregar Ítem'));
        await tester.pump();
        expect(tapped, 1);
      });
    });
  }
}
