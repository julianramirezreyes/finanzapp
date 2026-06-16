import 'package:finanzapp_v2/core/branding/brand_fallback.dart';
import 'package:finanzapp_v2/shared/ui/widgets/bank_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// WU-La3 — escenario L.3 [auto]: cuando la marca detectada tiene `asset`,
/// BankAvatar renderiza el LOGO (SvgPicture para .svg, Image para .png) sobre
/// un chip neutro; cuando no hay asset / es desconocida, cae al monograma.
/// Sin throw en LIGHT y DARK.
///
/// Nota: este contrato REEMPLAZA el de Fase 1 (monograma blanco sobre gradiente
/// para marcas conocidas). Ahora todas las marcas de kBankBrands tienen asset,
/// así que una marca conocida muestra su logo, NO el monograma.
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
    // Estático/asíncrono ligero (decodificación de asset): pump(Duration) por
    // convención, nunca pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 16));
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    final label = brightness == Brightness.dark ? 'dark' : 'light';

    group('L.3 [auto] BankAvatar en $label', () {
      testWidgets('marca con asset SVG (Nequi) renderiza un SvgPicture',
          (tester) async {
        await pump(
          tester,
          const BankAvatar(name: 'Nequi', type: 'cash'),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SvgPicture), findsOneWidget);
        // El logo reemplaza al monograma: no hay texto de iniciales.
        expect(find.text('NE'), findsNothing);
      });

      testWidgets('marca con asset PNG (Global66) renderiza un Image',
          (tester) async {
        await pump(
          tester,
          const BankAvatar(name: 'Global66', type: 'savings'),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Image), findsOneWidget);
        expect(find.byType(SvgPicture), findsNothing);
      });

      testWidgets('marca con asset PNG (PayU) renderiza un Image',
          (tester) async {
        await pump(
          tester,
          const BankAvatar(name: 'PayU', type: 'cash'),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('marca desconocida (Banco Raro) cae al monograma hash',
          (tester) async {
        await pump(
          tester,
          const BankAvatar(name: 'Banco Raro', type: 'savings'),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        // Sin asset -> sin logo, monograma con color de hash.
        expect(find.byType(SvgPicture), findsNothing);
        expect(find.text('BR'), findsOneWidget);

        final text = tester.widget<Text>(find.text('BR'));
        expect(text.style?.color, fallbackColorFor('Banco Raro'));
      });

      testWidgets('nombre vacío cae al icono por type sin throw',
          (tester) async {
        await pump(
          tester,
          const BankAvatar(name: '', type: 'credit'),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Icon), findsOneWidget);
        expect(find.byType(SvgPicture), findsNothing);
      });
    });
  }

  group('BankAvatar.accentFor', () {
    test('marca conocida -> primary; desconocida -> null', () {
      expect(BankAvatar.accentFor('Nequi'), isNotNull);
      expect(BankAvatar.accentFor('Banco Raro'), isNull);
    });
  });
}
