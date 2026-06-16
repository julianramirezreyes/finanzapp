import 'package:finanzapp_v2/shared/ui/widgets/branded_account_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WU-Lb1 — escenario L.4 [auto]: BrandedAccountSurface envuelve un child con un
/// wash difuminado del color de marca + watermark del logo, recortado a esquinas
/// redondeadas (ClipRRect). Sin throw en LIGHT y DARK. Para marca desconocida
/// degrada con gracia (sin watermark) sin romper.
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
        home: Scaffold(body: Center(child: child)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    final label = brightness == Brightness.dark ? 'dark' : 'light';

    group('L.4 [auto] BrandedAccountSurface en $label', () {
      testWidgets('marca conocida (Nequi): clip + wash + child', (tester) async {
        await pump(
          tester,
          const BrandedAccountSurface(
            name: 'Nequi',
            padding: EdgeInsets.all(16),
            child: Text('contenido'),
          ),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);

        // Recorte a esquinas redondeadas.
        expect(find.byType(ClipRRect), findsOneWidget);

        // Capa de wash: hay al menos un DecoratedBox con un LinearGradient.
        final hasGradient = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .any((d) {
          final dec = d.decoration;
          return dec is BoxDecoration && dec.gradient is LinearGradient;
        });
        expect(hasGradient, isTrue, reason: 'falta el wash con LinearGradient');

        // El contenido se renderiza.
        expect(find.text('contenido'), findsOneWidget);
      });

      testWidgets('marca desconocida (Banco Raro): degrada sin throw',
          (tester) async {
        await pump(
          tester,
          const BrandedAccountSurface(
            name: 'Banco Raro',
            child: Text('x'),
          ),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(ClipRRect), findsOneWidget);
        expect(find.text('x'), findsOneWidget);
      });
    });
  }
}
