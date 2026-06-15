import 'package:finanzapp_v2/core/theme/app_theme.dart';
import 'package:finanzapp_v2/shared/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escenarios 7.4 [auto] / 7.5-parcial [auto].
/// ScannerProgress usa un AnimationController con `.repeat()` (animación
/// infinita) -> en tests SIEMPRE `pump(Duration)`, NUNCA `pumpAndSettle`
/// (colgaría). El track resuelve por brillo via context.onSurface, no usa un
/// blanco opaco hardcodeado.
void main() {
  Widget host(ThemeData theme) => MaterialApp(
    theme: theme,
    home: const Scaffold(body: Center(child: ScannerProgress())),
  );

  testWidgets('ScannerProgress renderiza sin throw en lightTheme', (
    tester,
  ) async {
    await tester.pumpWidget(host(AppTheme.lightTheme));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(ScannerProgress), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ScannerProgress renderiza sin throw en darkTheme', (
    tester,
  ) async {
    await tester.pumpWidget(host(AppTheme.darkTheme));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(ScannerProgress), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el track del scanner NO es un blanco opaco hardcodeado', (
    tester,
  ) async {
    await tester.pumpWidget(host(AppTheme.darkTheme));
    await tester.pump(const Duration(milliseconds: 200));

    // El primer Container dentro del ScannerProgress es el track. Debe usar un
    // color translúcido derivado de onSurface, nunca Colors.white opaco.
    final track = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(ScannerProgress),
        matching: find.byType(Container),
      ),
    );

    for (final container in track) {
      final color = container.color;
      if (color != null) {
        expect(
          color,
          isNot(const Color(0xFFFFFFFF)),
          reason: 'el track no debe ser blanco opaco',
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('ScannerProgress no deja tickers colgando al desmontar', (
    tester,
  ) async {
    await tester.pumpWidget(host(AppTheme.lightTheme));
    await tester.pump(const Duration(milliseconds: 200));

    // Reemplazar el árbol fuerza el dispose() del State -> el controller debe
    // cancelarse sin lanzar "A Ticker was disposed" en el teardown.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );
    await tester.pump();

    expect(find.byType(ScannerProgress), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
