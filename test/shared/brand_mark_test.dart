import 'package:finanzapp_v2/core/theme/app_theme.dart';
import 'package:finanzapp_v2/shared/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escenarios 7.4 [auto] / 7.5-parcial [auto].
/// BrandMark debe renderizar sin throw en light y dark, con y sin glow, y
/// estar exportado por el barrel `shared/ui/ui.dart`.
void main() {
  Widget host(ThemeData theme, Widget child) =>
      MaterialApp(theme: theme, home: Scaffold(body: Center(child: child)));

  testWidgets('BrandMark renderiza sin throw en lightTheme', (tester) async {
    await tester.pumpWidget(host(AppTheme.lightTheme, const BrandMark()));

    expect(find.byType(BrandMark), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BrandMark renderiza sin throw en darkTheme', (tester) async {
    await tester.pumpWidget(host(AppTheme.darkTheme, const BrandMark()));

    expect(find.byType(BrandMark), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BrandMark acepta size y glow sin throw', (tester) async {
    await tester.pumpWidget(
      host(
        AppTheme.darkTheme,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 88, glow: 0.3),
            BrandMark(size: 64, glow: 1.0),
          ],
        ),
      ),
    );

    expect(find.byType(BrandMark), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
