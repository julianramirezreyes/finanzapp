import 'package:finanzapp_v2/core/branding/brand_fallback.dart';
import 'package:finanzapp_v2/shared/ui/widgets/bank_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WU-4 — escenario 8.5 [auto]: BankAvatar renderiza sin throw para marca
/// conocida, desconocida y nombre vacío, en LIGHT y DARK. El monograma de marca
/// es blanco sobre el gradiente (dark-mode-correcto: no usa nada hardcodeado
/// claro que se pierda en oscuro).
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
    // Estático, pero usamos pump(Duration) por convención (no pumpAndSettle).
    await tester.pump(const Duration(milliseconds: 16));
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    final label = brightness == Brightness.dark ? 'dark' : 'light';

    group('8.5 [auto] BankAvatar en $label', () {
      testWidgets('marca conocida (Nequi) renderiza gradiente + monograma blanco',
          (tester) async {
        await pump(
          tester,
          const BankAvatar(name: 'Nequi', type: 'cash'),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);

        // Hay un Container con gradient.
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.gradient, isA<LinearGradient>());

        // El monograma es blanco.
        expect(find.text('NE'), findsOneWidget);
        final text = tester.widget<Text>(find.text('NE'));
        expect(text.style?.color, Colors.white);
      });

      testWidgets('marca desconocida (Banco Raro) renderiza monograma hash',
          (tester) async {
        await pump(
          tester,
          const BankAvatar(name: 'Banco Raro', type: 'savings'),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
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
        expect(find.byType(Text), findsNothing);
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
