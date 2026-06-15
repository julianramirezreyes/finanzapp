import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escenario 6a.3 — helpers semánticos brightness-aware (AppColorsX).
/// En DARK, surface/border/onSurface resuelven los tokens oscuros y stateFill /
/// subtleFill NO devuelven el pastel claro (que sería un parche chillón sobre
/// fondo oscuro). En LIGHT devuelven los tokens claros / pasteles esperados.
///
/// Escenario 6a.6 — balancePositiveGradient eliminado: se valida por
/// compilación + flutter analyze (su call-site usa primaryGradient). No es
/// asertable en runtime, queda fuera de este archivo de test.
void main() {
  /// Monta un árbol bajo el brillo indicado y devuelve un BuildContext fresco
  /// leído DESPUÉS del pump (vía tester.element). Se usa una `key` distinta por
  /// brillo para forzar un Element nuevo y evitar reusar la suscripción al Theme
  /// anterior cuando se prueban ambos brillos en el mismo test.
  Future<BuildContext> contextFor(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    final key = ValueKey('probe-$brightness');
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme,
        home: SizedBox(key: key),
      ),
    );
    // MaterialApp envuelve el theme en AnimatedTheme (interpola 200ms). Sin
    // settle, el segundo pump aún reporta el brillo anterior.
    await tester.pumpAndSettle();
    return tester.element(find.byKey(key));
  }

  group('6a.3 AppColorsX brightness-aware (tabla-driven por brillo)', () {
    testWidgets('surface: dark -> surfaceDark, light -> surfaceLight', (
      tester,
    ) async {
      final dark = await contextFor(tester, Brightness.dark);
      expect(dark.surface, AppColors.surfaceDark);

      final light = await contextFor(tester, Brightness.light);
      expect(light.surface, AppColors.surfaceLight);
    });

    testWidgets('border: dark -> borderDark, light -> borderLight', (
      tester,
    ) async {
      final dark = await contextFor(tester, Brightness.dark);
      expect(dark.border, AppColors.borderDark);

      final light = await contextFor(tester, Brightness.light);
      expect(light.border, AppColors.borderLight);
    });

    testWidgets('onSurface: dark != textPrimary claro; light == textPrimary', (
      tester,
    ) async {
      final dark = await contextFor(tester, Brightness.dark);
      expect(dark.onSurface, isNot(AppColors.textPrimary));

      final light = await contextFor(tester, Brightness.light);
      expect(light.onSurface, AppColors.textPrimary);
    });

    testWidgets('subtleFill: dark NO es pastel claro; light es fondo claro', (
      tester,
    ) async {
      final dark = await contextFor(tester, Brightness.dark);
      expect(dark.subtleFill(), isNot(AppColors.primarySurface));
      expect(dark.subtleFill(), isNot(AppColors.backgroundLight));

      final light = await contextFor(tester, Brightness.light);
      expect(light.subtleFill(), AppColors.backgroundLight);
    });

    testWidgets('stateFill: dark NO es incomeLight; light es base translúcido', (
      tester,
    ) async {
      final dark = await contextFor(tester, Brightness.dark);
      final darkFill = dark.stateFill(AppColors.income);
      expect(darkFill, isNot(AppColors.incomeLight));
      expect(darkFill, isNot(AppColors.primarySurface));

      final light = await contextFor(tester, Brightness.light);
      // En light el fill es el color base a baja opacidad (pastel suave).
      expect(light.stateFill(AppColors.income).a, lessThan(1.0));
    });
  });
}
