import 'package:finanzapp_v2/shared/ui/widgets/branded_screen_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// boveda-brand-backdrop [auto]: BrandedScreenBackground envuelve un child con
/// un WASH vertical full-screen del color de marca (de arriba hacia transparente)
/// + un WATERMARK del logo en la zona superior. Sin throw en LIGHT y DARK. Para
/// marca desconocida degrada con gracia (sin watermark) sin romper. Espejo de
/// branded_account_surface_test.dart.
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

    group('[auto] BrandedScreenBackground en $label', () {
      testWidgets('marca conocida (Bancolombia): wash + child sin throw',
          (tester) async {
        await pump(
          tester,
          const BrandedScreenBackground(
            name: 'Bancolombia',
            child: Text('contenido'),
          ),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);

        // Es un Stack (backdrop + child por encima).
        expect(find.byType(Stack), findsWidgets);

        // Capa de wash: hay al menos un DecoratedBox con un LinearGradient.
        final hasGradient = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .any((d) {
          final dec = d.decoration;
          return dec is BoxDecoration && dec.gradient is LinearGradient;
        });
        expect(hasGradient, isTrue, reason: 'falta el wash con LinearGradient');

        // El watermark no intercepta gestos.
        expect(find.byType(IgnorePointer), findsWidgets);

        // El contenido se renderiza por encima.
        expect(find.text('contenido'), findsOneWidget);
      });

      testWidgets('marca desconocida (Banco Raro): degrada sin watermark',
          (tester) async {
        await pump(
          tester,
          const BrandedScreenBackground(
            name: 'Banco Raro',
            child: Text('x'),
          ),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);

        // Sigue habiendo wash (fallback color) y el child se renderiza.
        final hasGradient = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .any((d) {
          final dec = d.decoration;
          return dec is BoxDecoration && dec.gradient is LinearGradient;
        });
        expect(hasGradient, isTrue, reason: 'falta el wash con LinearGradient');
        expect(find.text('x'), findsOneWidget);

        // Marca desconocida -> sin asset -> sin watermark (sin imagen/SVG).
        expect(find.byType(Image), findsNothing);
      });

      testWidgets(
          'showLogo:false oculta el watermark pero conserva el wash + child',
          (tester) async {
        await pump(
          tester,
          const BrandedScreenBackground(
            name: 'Bancolombia',
            showLogo: false,
            child: Text('solo wash'),
          ),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);

        // El wash sigue presente.
        final hasGradient = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .any((d) {
          final dec = d.decoration;
          return dec is BoxDecoration && dec.gradient is LinearGradient;
        });
        expect(hasGradient, isTrue, reason: 'falta el wash con LinearGradient');

        // El child se renderiza por encima.
        expect(find.text('solo wash'), findsOneWidget);

        // showLogo:false -> SIN watermark (ni Image ni SvgPicture).
        expect(find.byType(Image), findsNothing);
        expect(find.byType(SvgPicture), findsNothing);
      });
    });
  }
}
